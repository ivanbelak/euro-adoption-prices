"""Download HICP (harmonised consumer price) data from Eurostat.

Downloads the full prc_hicp_minr dataset (HICP, ECOICOP ver.2 classification)
as a compressed TSV and reshapes it into long (tidy) format:
one row = one country x category x month x unit.

Note: Eurostat switched to ECOICOP ver.2 in 2026. The older datasets
(prc_hicp_manr, prc_hicp_midx) are frozen at 2025-12, so they must not be used.

Usage (from the project root):
    python src/fetch_eurostat.py            # skip download if the file exists
    python src/fetch_eurostat.py --refresh  # force a fresh download

Output (all in data/raw/, which is git-ignored):
    prc_hicp_minr.tsv.gz   original download (~35 MB)
    hicp_long.parquet      tidy version (~22M rows, all countries)
    dim_coicop.csv         category codes and names
    dim_geo.csv            country codes and names
"""

import argparse
from pathlib import Path

import pandas as pd
import requests

DATASET = "prc_hicp_minr"
BULK_URL = (
    "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/"
    f"{DATASET}/?format=TSV&compressed=true"
)
JSON_URL = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
    f"{DATASET}"
)

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"


def download_bulk(dest: Path) -> None:
    """Download the whole dataset (~35 MB, takes 1-2 minutes)."""
    print(f"Downloading {BULK_URL} ...")
    with requests.get(BULK_URL, stream=True, timeout=600) as r:
        r.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in r.iter_content(chunk_size=1 << 20):
                f.write(chunk)
    print(f"  saved: {dest} ({dest.stat().st_size / 1e6:.1f} MB)")


def tsv_to_long(src: Path) -> pd.DataFrame:
    """Eurostat TSV (wide, one column per month) -> long format.

    Cell values look like this:
        "101.23"    plain value
        "68.98 d"   value + flag (d = definition differs, p = provisional, ...)
        ":"         not available
        ": u"       not available, with a flag
    """
    wide = pd.read_csv(src, sep="\t", dtype=str, compression="gzip")
    key_col = wide.columns[0]  # "freq,unit,coicop18,geo\TIME_PERIOD"
    keys = wide[key_col].str.split(",", expand=True)
    keys.columns = ["freq", "unit", "coicop", "geo"]
    wide = pd.concat([keys, wide.drop(columns=key_col)], axis=1)
    wide.columns = [c.strip() for c in wide.columns]

    long = wide.melt(
        id_vars=["freq", "unit", "coicop", "geo"],
        var_name="period",
        value_name="raw",
    )
    long["raw"] = long["raw"].str.strip()
    long = long[~long["raw"].str.startswith(":")]  # drop missing cells

    parts = long["raw"].str.extract(r"^(?P<value>[-\d.]+)\s*(?P<flag>[a-z]*)$")
    long["value"] = pd.to_numeric(parts["value"], errors="coerce")
    long["flag"] = parts["flag"].fillna("")
    long["date"] = pd.to_datetime(long["period"], format="%Y-%m")

    long = long.drop(columns=["raw", "period", "freq"])
    return long[["geo", "coicop", "unit", "date", "value", "flag"]].reset_index(drop=True)


def fetch_labels() -> tuple[pd.DataFrame, pd.DataFrame]:
    """Category and country names (the TSV only has codes)."""
    r = requests.get(
        JSON_URL,
        params={"geo": "HR", "unit": "I15", "sinceTimePeriod": "2025-01",
                "format": "JSON", "lang": "EN"},
        timeout=120,
    )
    r.raise_for_status()
    coicop = r.json()["dimension"]["coicop18"]["category"]["label"]
    dim_coicop = pd.DataFrame(list(coicop.items()), columns=["coicop", "label_en"])

    # Country labels need every country, hence a second query without a geo filter
    r = requests.get(
        JSON_URL,
        params={"coicop18": "TOTAL", "unit": "I15", "sinceTimePeriod": "2026-01",
                "format": "JSON", "lang": "EN"},
        timeout=120,
    )
    r.raise_for_status()
    geo = r.json()["dimension"]["geo"]["category"]["label"]
    dim_geo = pd.DataFrame(list(geo.items()), columns=["geo", "label_en"])
    return dim_coicop, dim_geo


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true", help="force a fresh download")
    args = parser.parse_args()

    RAW.mkdir(parents=True, exist_ok=True)
    tsv = RAW / f"{DATASET}.tsv.gz"
    if args.refresh or not tsv.exists():
        download_bulk(tsv)
    else:
        print(f"Using existing {tsv.name} (pass --refresh to re-download)")

    print("Reshaping to long format ...")
    long = tsv_to_long(tsv)
    long.to_parquet(RAW / "hicp_long.parquet", index=False)
    print(f"  {len(long):,} rows, "
          f"{long['geo'].nunique()} countries, {long['coicop'].nunique()} categories, "
          f"{long['date'].min():%Y-%m} -> {long['date'].max():%Y-%m}")

    print("Fetching category and country names ...")
    dim_coicop, dim_geo = fetch_labels()
    # utf-8-sig (with BOM) so Power BI / Excel show "ü" and "–" correctly
    dim_coicop.to_csv(RAW / "dim_coicop.csv", index=False, encoding="utf-8-sig")
    dim_geo.to_csv(RAW / "dim_geo.csv", index=False, encoding="utf-8-sig")
    print("Done.")


if __name__ == "__main__":
    main()
