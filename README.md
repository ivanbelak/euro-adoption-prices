# Did the euro make Croatia more expensive?

> 🚧 **Work in progress.** Data pipeline, database and a first event study are done; statistical tests and the Power BI report are next.

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
| Analyse | Event study: align every euro adopter on its adoption month, rebase to 100 the month before, compare with five controls (EA19, HU, PL, CZ, RO) over the same months | [`sql/05_event_study.sql`](sql/05_event_study.sql), [`sql/06_event_study_findings.sql`](sql/06_event_study_findings.sql) |

## Findings so far

**Method.** Six countries adopted the euro with at least a year of data since: Slovenia (2007),
Slovakia (2009), Estonia (2011), Latvia (2014), Lithuania (2015) and Croatia (2023). Each one is
aligned on its own adoption month and rebased to 100 in the month before. The same is done for a
control over the same calendar months, and **excess** = adopter − control, in index points.
Shocks that hit both (energy, interest rates, war) cancel out; what is left is closer to the effect
of the changeover itself.

**Services, one year after adoption** (excess in index points, by control):

| Adopter | vs EA19 | vs Hungary | vs Poland | vs Czechia | vs Romania |
|---|---|---|---|---|---|
| Croatia | **+4.1** | −4.1 | +0.4 | +0.1 | −1.6 |
| Slovenia | +2.7 | −1.0 | +2.6 | +2.3 | −2.7 |
| Estonia | +2.2 | +1.5 | −0.3 | +2.2 | +1.3 |
| Lithuania | +2.6 | +1.8 | +2.1 | +2.9 | +1.2 |
| Latvia | +1.8 | +1.4 | +1.5 | +2.1 | +0.4 |
| Slovakia | +1.2 | −2.7 | −1.3 | +1.0 | −3.4 |

- **Against the euro area, services rose faster in all six adopters**, Croatia most of all.
  This fits the usual rounding story: cheap, frequently bought services (coffee, haircuts, repairs)
  are where a price is easiest to round up.
- **The result depends on the control.** For Lithuania and Latvia it holds against every control.
  For Croatia it largely disappears against non-euro neighbours: part of the gap with the euro area
  looks like something Central and Eastern Europe shared in 2023 (e.g. fast wage growth), not the euro.
- Large excesses in single categories need a story before they count as a euro effect.
  Croatian passenger transport (+16.6 vs EA19) reflects Germany's €49 Deutschlandticket (May 2023)
  pulling the euro-area index down; electricity and gas reflect Croatian price caps.

Every control has its own shocks: Hungary had ~25% inflation in early 2023, and Poland and Hungary
saw sharp currency depreciation in 2009, when Slovakia adopted the euro.

## Notes on the data

- Eurostat moved HICP to the **ECOICOP ver.2** classification in 2026. The older datasets
  (`prc_hicp_manr`, `prc_hicp_midx`) stop at December 2025, so this project uses `prc_hicp_minr`.
- The "euro area" aggregate `EA` changes composition over time and includes Croatia from 2023.
  Comparisons use `EA19`, a fixed-composition series without Croatia and Bulgaria.
- Data quality check: across 1.77M data points, recomputed and published inflation rates differ by
  more than 1 percentage point in only 112 cases, mostly Romania 1997–99 (rounding during very high inflation).
- Published indices are rounded to two decimals, so a 2015 average comes out at e.g. 99.998 rather than 100.
- **Some indices are exactly 0.** A few are real: Bulgaria made kindergartens free from April 2022, and
  Estonian passenger transport hit 0 during the 2020 lockdown. Others (e.g. Romanian streaming
  subscriptions, 2018–2023) look like gaps. Growth from 0 is undefined, so these rows get a NULL excess.
- **Detailed categories are missing for older adoptions.** The most detailed levels (e.g. "coffee")
  only start in 2014–2016 for most controls, so for Slovenia, Slovakia and Latvia about half the rows
  have no excess. Cross-country comparisons therefore use category level 3 or Eurostat's aggregates
  (services, food, energy), where coverage is above 94%.

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
