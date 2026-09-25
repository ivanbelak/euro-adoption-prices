"""Load the downloaded data into SQL Server (database EuroPrices).

Runs the scripts in sql/ in order, loads staging and dimension tables
from data/raw and data/seed, then lets SQL build the fact table.

Usage (from the project root, after fetch_eurostat.py and fetch_fred.py):
    python src/load_sql.py

Connection: Windows authentication to localhost by default.
Override with the SQL_SERVER environment variable, e.g. SQL_SERVER=localhost\\SQLEXPRESS
"""

import os
import re
import time
from pathlib import Path

import pandas as pd
import pyodbc

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
SEED = ROOT / "data" / "seed"
SQL = ROOT / "sql"

SERVER = os.environ.get("SQL_SERVER", "localhost")
DATABASE = "EuroPrices"
UNITS = ["I15", "RCH_A", "RCH_M"]  # index, year-over-year %, month-over-month %
BATCH = 100_000


def connect(database: str) -> pyodbc.Connection:
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={SERVER};DATABASE={database};"
        "Trusted_Connection=yes;TrustServerCertificate=yes;",
        autocommit=True,
    )


def run_script(conn: pyodbc.Connection, path: Path) -> None:
    """Run a .sql file, splitting it on GO lines like sqlcmd/SSMS do."""
    batches = re.split(r"^\s*GO\s*$", path.read_text(encoding="utf-8"), flags=re.M | re.I)
    cur = conn.cursor()
    for batch in batches:
        if batch.strip():
            cur.execute(batch)
    print(f"  ran {path.name}")


def insert_df(conn: pyodbc.Connection, table: str, df: pd.DataFrame) -> None:
    cols = ", ".join(df.columns)
    params = ", ".join("?" * len(df.columns))
    sql = f"INSERT INTO {table} WITH (TABLOCK) ({cols}) VALUES ({params})"
    rows = list(df.itertuples(index=False, name=None))
    t0 = time.time()
    # One transaction per table: with autocommit every row is committed
    # separately and the load is ~12x slower (13k vs 160k rows/s).
    conn.autocommit = False
    try:
        cur = conn.cursor()
        cur.fast_executemany = True
        for i in range(0, len(rows), BATCH):
            cur.executemany(sql, rows[i:i + BATCH])
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.autocommit = True
    print(f"  {table}: {len(rows):,} rows ({time.time() - t0:.0f}s)")


def category_level(code: str) -> int | None:
    """TOTAL -> 0, CP01 -> 1, CP011 -> 2, ... ; special aggregates -> None."""
    if code == "TOTAL":
        return 0
    m = re.fullmatch(r"CP(\d+)", code)
    return len(m.group(1)) - 1 if m else None


def parent_code(code: str) -> str | None:
    level = category_level(code)
    if level is None or level == 0:
        return None
    return "TOTAL" if level == 1 else code[:-1]


def build_categories() -> pd.DataFrame:
    df = pd.read_csv(RAW / "dim_coicop.csv", encoding="utf-8-sig")
    df = df.rename(columns={"coicop": "coicop_code", "label_en": "category_name"})
    df["category_level"] = df["coicop_code"].map(category_level).astype("Int64")
    df["parent_code"] = df["coicop_code"].map(parent_code)
    df["is_special_aggregate"] = df["category_level"].isna()
    # pyodbc wants None, not pandas NA
    return df.astype(object).where(df.notna(), None)


def main() -> None:
    print(f"Connecting to {SERVER} ...")
    with connect("master") as conn:
        run_script(conn, SQL / "01_create_database.sql")

    with connect(DATABASE) as conn:
        run_script(conn, SQL / "02_tables.sql")

        countries = pd.read_csv(SEED / "countries.csv", dtype={"euro_adoption_date": str})
        countries["is_aggregate"] = countries["is_aggregate"].astype(bool)
        countries = countries.astype(object).where(countries.notna(), None)
        insert_df(conn, "dim.country", countries)

        insert_df(conn, "dim.category", build_categories())

        hicp = pd.read_parquet(
            RAW / "hicp_long.parquet",
            filters=[("geo", "in", list(countries["country_code"])), ("unit", "in", UNITS)],
        )
        hicp = hicp.rename(columns={"geo": "country_code", "coicop": "coicop_code",
                                    "date": "month_date"})
        hicp["month_date"] = hicp["month_date"].dt.date
        insert_df(conn, "stg.hicp", hicp[["country_code", "coicop_code", "unit",
                                          "month_date", "value", "flag"]])

        us = pd.read_csv(RAW / "us_cpi.csv", parse_dates=["date"])
        us = us.rename(columns={"date": "month_date"})
        us["month_date"] = us["month_date"].dt.date
        insert_df(conn, "stg.us_cpi", us)

        run_script(conn, SQL / "03_transform.sql")
        run_script(conn, SQL / "04_views.sql")

        cur = conn.cursor()
        for table in ["dim.country", "dim.category", "dim.calendar",
                      "fact.hicp_monthly", "ref.us_cpi"]:
            n = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            print(f"  {table}: {n:,}")
    print("Done.")


if __name__ == "__main__":
    main()
