# Did the euro make Croatia more expensive?

> 🚧 **Work in progress.** Data pipeline and database are done; analysis and Power BI report are next.

Croatia adopted the euro on 1 January 2023. Between December 2022 and August 2026, consumer
prices in Croatia rose **19.0%**, compared with **10.7%** in the euro area (EA19, excluding Croatia).
But prices in non-euro neighbours like Hungary and Poland also rose ~16%.
So how much of it was the euro, and how much was everything else?

This project tries to answer that with official Eurostat data, comparing Croatia with:
- **the euro area** (fixed 19-country composition, so Croatia itself isn't in the benchmark),
- **earlier euro adopters** (Slovenia 2007, Slovakia 2009, Estonia 2011, Latvia 2014, Lithuania 2015),
- **Bulgaria**, which adopted the euro in 2026,
- **non-euro peers** (Hungary, Poland, Czechia, Romania),
- **the US** as global context (CPI from FRED; not methodologically identical to HICP).

## Pipeline

```
Eurostat (HICP)  ─┐
                  ├─ Python ─→ SQL Server ─→ Power BI
FRED (US CPI)   ──┘            stg → dim / fact → pbi views
                                          └─→ qa checks
```

| Step | What | Where |
|---|---|---|
| Extract | Full Eurostat `prc_hicp_minr` dataset (46 countries, 555 categories, 1996–2026) and US CPI | [`src/fetch_eurostat.py`](src/fetch_eurostat.py), [`src/fetch_fred.py`](src/fetch_fred.py) |
| Load | Staging + dimension tables, ~5.5M rows in ~30s | [`src/load_sql.py`](src/load_sql.py) |
| Transform | Star schema in SQL: pivot units, build calendar | [`sql/`](sql/) |
| Validate | Recompute year-over-year inflation from the index and compare with Eurostat's published rate | [`sql/04_views.sql`](sql/04_views.sql) (`qa.yoy_check`) |

## Notes on the data

- Eurostat moved HICP to the **ECOICOP ver.2** classification in 2026. The older datasets
  (`prc_hicp_manr`, `prc_hicp_midx`) stop at December 2025, so this project uses `prc_hicp_minr`.
- The "euro area" aggregate `EA` changes composition over time and includes Croatia from 2023.
  Comparisons use `EA19`, a fixed-composition series without Croatia and Bulgaria.
- Data quality check: across 1.77M data points, recomputed and published inflation rates differ by
  more than 1 percentage point in only 112 cases, mostly Romania 1997–99 (rounding during very high inflation).

## Running it

Requires [conda](https://docs.conda.io/) and SQL Server (Express is fine) with ODBC Driver 18.

```bash
conda env create -f environment.yml
conda activate euro-cijene
python src/fetch_eurostat.py
python src/fetch_fred.py
python src/load_sql.py        # set SQL_SERVER=... if not localhost
pytest
```

## Tools

Built with Python (pandas, pyodbc), SQL Server and Power BI. Developed with help from
[Claude Code](https://claude.com/claude-code) as a coding assistant. All data is public.
