# Did the euro make Croatia more expensive?

> 🚧 **Work in progress.** Data pipeline, database, event study and Power BI report are done;
> statistical tests (confidence intervals, placebo test) are next.

Croatia adopted the euro on 1 January 2023. Between December 2022 and August 2026, consumer
prices in Croatia rose **19.0%**, compared with **10.7%** in the euro area (EA19, excluding Croatia).
But prices in non-euro neighbours like Hungary and Poland also rose ~16%.
So how much of it was the euro, and how much was everything else?

This project tries to answer that with official Eurostat data, comparing every country that
adopted the euro since 2007 (Slovenia, Slovakia, Estonia, Latvia, Lithuania, Croatia and, from 2026,
Bulgaria) with two kinds of controls that did **not** change currency at the same time:
- **the euro area** (EA19, a fixed 19-country composition without Croatia and Bulgaria),
- **non-euro peers**: Hungary, Poland, Czechia and Romania, one by one and on average.

The US (CPI from FRED) is included as global context only.

![Croatia vs the euro area: prices and excess around euro adoption](docs/img/croatia_vs_control.png)

## Findings so far

**In short:** in all six adoptions with a full year of data, **services** got more expensive than in
the controls during the first year of the euro, by roughly 0.3 to 3.4 index points once
pre-existing trends are removed. **Goods** show no consistent effect. For **Croatia** the direction is
clear but the size is not: it ranges from about +0.3 to +4 points, depending on the control and on
how the pre-euro trend is measured.

### Method

1. **Align** every adopter on its own adoption month (month 0) and rebase prices to 100 in the month before.
2. **Compare** with a control over the same calendar months, rebased the same way.
   **Excess** = adopter − control, in index points. Shocks that hit both (energy, interest rates, war) cancel out.
3. **Remove the pre-existing trend.** Croatia's prices were already rising faster than the euro area's
   before 2023 (it is a catching-up economy with fast wage growth). A straight line is fitted through
   excess over the last 12/24/36/48 months before adoption and extended past month 0; only the excess
   *above* that line is counted.
4. **Smooth the tourist season.** Croatian services jump every summer, so the headline number compares
   the average excess over the first year of the euro (months 0–11) with the year before (months −12 to −1).

### Services: the euro effect, by adopter and control

Trend-adjusted change in excess, first year of the euro vs the year before (index points, 24-month trend window):

| Adopter (year) | vs euro area (EA19) | vs non-euro peers (average) |
|---|---|---|
| Latvia (2014) | +2.5 | +2.6 |
| Estonia (2011) | +2.4 | +3.4 |
| Croatia (2023) | +1.8 | +0.3 |
| Lithuania (2015) | +1.2 | +1.5 |
| Slovenia (2007) | +0.9 | +0.9 |
| Slovakia (2009) | +0.5 | +0.4 |

- **Positive in all twelve cases.** This fits the usual rounding story: cheap, frequently bought services
  (coffee, haircuts, repairs) sold by small businesses are where a price is easiest to round up, while
  goods sold by large chains in competitive markets are not. Against non-euro peers, goods are mixed
  (−2.6 to +1.4), so goods serve as a check rather than a finding.
- **The shape is a step, not a slope.** After removing the old trend, excess rises during the first year
  and then stays flat: a one-off level change at the changeover, not permanently faster inflation.
- **Two very different controls agree.** The euro area grows more slowly than Croatia; the non-euro peers
  grow faster and had their own shocks (Hungary had ~25% inflation in early 2023). Before removing trends,
  Croatia's services excess was +4.1 against the euro area and −1.3 against the peers. After removing
  them, the two controls give similar answers for most adopters.

### Why Croatia is the hardest case

Croatian services, change in excess vs EA19 by **trend window** (how many pre-euro months the trend is fitted on):

| Trend window | ±12 | ±24 | ±36 | ±48 |
|---|---|---|---|---|
| Pre-euro trend (points per year) | 6.7 | 3.2 | 1.9 | 1.1 |
| Euro effect on services | −1.6 | +1.8 | +3.2 | +4.0 |

- Croatia adopted the euro at the peak of an inflation surge. A short window sees only the 2022
  acceleration and treats it as the "normal" trend, which absorbs the whole effect; a long window
  reaches back to calmer years (and to COVID in 2020). Baltic and Slovenian results move far less.
- **Anticipation.** The conversion rate was fixed in July 2022 and dual pricing (kuna and euro) was
  mandatory from September 2022, four months before the changeover. Some rounding probably happened
  before month 0, inside the window used to fit the trend, which would make these estimates too *low*.
- The ±12 window covers a single tourist season and is the least reliable of the four.

### Single categories need a story first

The largest excesses in Croatia are not euro effects: passenger transport (+16.6 vs EA19, one year after)
reflects Germany's €49 Deutschlandticket (May 2023) pulling the euro-area index down, and electricity
and gas reflect Croatian price caps. With ~140 categories compared at once, a few will also look large
by chance; the analysis therefore leans on services as a whole, which theory pointed to in advance.

## Power BI report

[`powerbi/EuroPrices.pbip`](powerbi/) (Power BI Project format: the model is TMDL and the report is PBIR,
so both are plain text and diff cleanly in git). Four pages:

| Page | Question |
|---|---|
| **Croatia vs control** | What happened to prices around adoption, for one adopter against one control? |
| **All adopters** | Does the same pattern repeat in every adoption? (small multiples) |
| **Robustness** | Does the result survive a different control? (adopter × control matrix) |
| **Croatia by category** | Which prices pulled away, and which of those are false alarms? |

Slicers pick the adopter, the control, the **trend window** (±12 to ±48 months) and the category
(17 headline aggregates such as services, goods, food and energy, plus COICOP levels 1–3, grouped by division).
Measures are window-aware DAX (`SELECTEDVALUE`, `CALCULATE`, `AVERAGEX`), with 12-month trailing averages
to remove seasonality. Opening it needs the database below; after opening, click **Refresh**.

## Pipeline

```
Eurostat (HICP)  ─┐
                  ├─ Python ─→ SQL Server ─────────────────────────→ Power BI
FRED (US CPI)   ──┘            stg  →  dim / fact  →  pbi views
                               bronze   silver        gold
                                            └─→ qa checks
```

The database follows a medallion-style layout: `stg` holds raw data as loaded (bronze),
`dim`/`fact` the cleaned star schema (silver), and `pbi` the analysis views the report reads (gold).

| Step | What | Where |
|---|---|---|
| Extract | Full Eurostat `prc_hicp_minr` dataset (46 countries, 555 categories, 1996–2026) via the Eurostat API; US CPI from FRED | [`src/fetch_eurostat.py`](src/fetch_eurostat.py), [`src/fetch_fred.py`](src/fetch_fred.py) |
| Load | Staging and dimension tables, ~5.5M rows in ~30 s | [`src/load_sql.py`](src/load_sql.py) |
| Transform | Star schema in SQL: pivot units, build calendar, category hierarchy | [`sql/01`–`04`](sql/) |
| Validate | Recompute inflation from the index and compare with Eurostat's published rate | [`sql/04_views.sql`](sql/04_views.sql) (`qa.yoy_check`) |
| Event study | Align adopters, rebase, pair with every control (CTEs, window functions, `CROSS JOIN`) | [`sql/05_event_study.sql`](sql/05_event_study.sql) |
| Pre-trends | OLS slope of excess before adoption for four windows; trend-adjusted excess | [`sql/07_pre_trends.sql`](sql/07_pre_trends.sql) |
| Explore | Queries behind the findings above | [`sql/06_event_study_findings.sql`](sql/06_event_study_findings.sql) |

## Data quality

- **Validation against the source.** Inflation recomputed from the index matches Eurostat's published
  rate within 1 percentage point in all but 112 of 1.77M data points, mostly Romania 1997–99
  (rounding during very high inflation).
- **A classification change.** Eurostat moved HICP to **ECOICOP ver.2** in 2026; the older datasets
  (`prc_hicp_manr`, `prc_hicp_midx`) silently stop at December 2025. This project uses `prc_hicp_minr`.
- **Indices that are exactly 0.** Some are real (Bulgaria made kindergartens free from April 2022;
  Estonian passenger transport hit 0 in the 2020 lockdown), some look like gaps (Romanian streaming
  subscriptions, 2018–2023). Growth from 0 is undefined, so every division is guarded with `NULLIF`
  and those rows get no excess.
- **Rounding.** Published indices have two decimals, so a 2015 average comes out at e.g. 99.998, not 100.
- **Uneven coverage.** The most detailed categories (e.g. "coffee") start only in 2014–2016 for most
  controls, so for Slovenia, Slovakia and Latvia about half of those rows have no excess. Cross-country
  comparisons use COICOP levels 1–3 and Eurostat's aggregates, where coverage is above 94%.
- **Fixed-composition benchmark.** The euro-area series `EA` changes membership and includes Croatia from
  2023, so comparisons use `EA19`. EA19 does contain the earlier adopters themselves, each with a weight
  of around 1% or less, which slightly understates their excess.

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

Then open `powerbi/EuroPrices.pbip` in Power BI Desktop and click **Refresh** (the server and database
are Power Query parameters, `SQL Server` and `SQL Database`).

## Tools

Built with Python (pandas, pyodbc), SQL Server and Power BI. Developed with help from
[Claude Code](https://claude.com/claude-code) as a coding assistant. All data is public.
