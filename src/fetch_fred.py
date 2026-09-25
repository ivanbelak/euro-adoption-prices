"""Download US consumer prices (CPI-U) from FRED, for global context.

Eurostat only carries a US total index up to 2024, so we take the official
BLS series from FRED instead. Series CPIAUCNS = CPI for all urban consumers,
NOT seasonally adjusted (HICP is not seasonally adjusted either).

Caveat: US CPI is not methodologically identical to HICP (e.g. CPI includes
owner-occupied housing costs). Use it as context, not as a like-for-like
comparison.

Usage (from the project root):
    python src/fetch_fred.py
"""

from io import StringIO
from pathlib import Path

import pandas as pd
import requests

SERIES = "CPIAUCNS"
URL = f"https://fred.stlouisfed.org/graph/fredgraph.csv?id={SERIES}"

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    r = requests.get(URL, timeout=120)
    r.raise_for_status()
    df = pd.read_csv(StringIO(r.text), parse_dates=["observation_date"])
    df.columns = ["date", "cpi_u_nsa"]
    df = df.dropna()
    df.to_csv(RAW / "us_cpi.csv", index=False)
    print(f"US CPI: {len(df)} months, {df.date.min():%Y-%m} -> {df.date.max():%Y-%m}")


if __name__ == "__main__":
    main()
