# Methodology and detailed results

[← Back to the README](../README.md) · [🇭🇷 Hrvatski](METODOLOGIJA.md)

## The question

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

## Results

**In short:** in all six adoptions with a full year of data, **services** got more expensive than in
the controls during the first year of the euro, by roughly 0.3 to 3.4 index points once
pre-existing trends are removed. Averaged over the six adoptions that is about **+1.5 points, more than
97% of fake adoption dates produce** against the euro area (90% against the non-euro peers).
**Goods** and **all items** show nothing beyond the noise. For **Croatia** alone the direction matches but
the evidence is borderline, and the size ranges from about +0.3 to +4 points depending on the control and
on how the pre-euro trend is measured.

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

### Reading the breakdown

The first page of the report splits the price rise into three parts. For Croatian services against the euro
area, averaged over the first 24 months of the euro:

| | Index points |
|---|---|
| Price rise in Croatia | +10.8 |
| minus the price rise in the control over the same months | −5.0 |
| minus the pre-euro trend | −3.4 |
| **= estimated euro effect** | **+2.4** |

An analogy: you got a 10% raise. Everyone in the company got 5% for inflation, and you have always got about
3% more than the average, promotion or not. What the promotion itself added is about 10 − 5 − 3 = 2%.

- **The control** removes what happened to everyone *at the same time*: the energy crisis, interest rates,
  global supply problems.
- **The pre-euro trend** removes what Croatia was *already doing before*: rising faster than the euro area as
  a catching-up economy with fast wage growth and booming tourism.

**Nothing is subtracted twice.** The trend is fitted to the *gap* between Croatia and the control before the
euro, not to Croatia's own price rise, so general inflation is already out of it. If Croatia and the control
had both risen 5% a year before the euro, the gap would be flat and the trend bar would be zero. The three
steps add up exactly.

**Where it can go wrong** is the line between the trend and the euro:
- *Anticipation.* Prices were shown in euros from September 2022. Any rounding before January 2023 sits in the
  period the trend is fitted on, so part of the euro effect ends up in the trend bar and the estimate is too low.
- *Temporary shocks that look like a trend.* A gap that opened for a temporary reason (for example, the 2022
  energy crisis hitting countries differently) is extended into the future as if it were permanent. Against
  the non-euro peers, whose own 2022 inflation surge was larger, the trend bar even turns positive: Croatia was
  expected to keep falling behind, and did not.

The **Control** slicer changes the second bar and the **Window** slicer the third (how many pre-euro months the
trend is fitted on), so the report shows directly how much the answer depends on each choice.

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

### Which services?

The same step, computed for each service category with data in at least five of the six adoptions
(24-month trend window). "Higher in" counts the adoptions where the category rose more than in the control.

| Service | vs euro area: higher in | avg | vs non-euro peers: higher in | avg |
|---|---|---|---|---|
| Restaurants, cafés | 6 of 6 | +2.6 | 5 of 6 | +2.7 |
| Canteens and cafeterias | 6 of 6 | +3.5 | 5 of 6 | +3.2 |
| Recreation and personal care (aggregate) | 6 of 6 | +2.3 | 6 of 6 | +2.2 |
| Hairdressing and personal grooming | 6 of 6 | +2.2 | 4 of 6 | +2.0 |
| Repair of household appliances | 6 of 6 | +2.5 | 4 of 6 | +2.2 |
| Recreational and sporting services | 5 of 6 | +2.7 | 5 of 6 | +2.2 |
| Dental services | 5 of 6 | +1.8 | 5 of 6 | +1.5 |
| *for comparison:* | | | | |
| Mobile communication | 4 of 6 | −0.3 | 3 of 6 | −1.1 |
| Internet access | 3 of 5 | −5.2 | 0 of 5 | −5.6 |
| Passenger transport by railway | 1 of 6 | −0.9 | 4 of 6 | −0.1 |

The effect is clearest where people pay small amounts often and the sellers are small businesses; it is
absent where prices are set by large companies or the state. Air fares have the largest average but swing
wildly (Croatia +39 against the euro area), so they are left out as noise. This table is descriptive: with
~40 service categories compared at once some will look large by chance, and no placebo test was run per
category, which is why the count of adoptions is a better guide than the average.

### Is it more than noise? A placebo test

Any method applied to noisy monthly data reports *some* number. To measure that noise, the same calculation is
run for **fake adoption dates**: every month from 18 to 240 months before the real one, as far back as the data
goes. The 18-month gap keeps the fake "year after" clear of the months when prices were already shown in euros.
See [`notebooks/01_placebo_test.ipynb`](../notebooks/01_placebo_test.ipynb).

One country at a time the test is weak (Latvia's fake estimates range from −10 to +6, through the 2008-10 crisis).
Averaged over the six adoptions, the noise partly cancels while a genuine changeover effect should not:

| Average of six adoptions | Real | 90% of fake averages | p |
|---|---|---|---|
| Services vs euro area | **+1.54** | −2.31 to +1.36 | **0.03** |
| Services vs non-euro peers | **+1.50** | −2.01 to +1.84 | 0.10 |
| Goods vs euro area | +0.91 | −1.74 to +1.28 | 0.12 |
| Goods vs non-euro peers | −0.48 | −1.79 to +1.71 | 0.69 |
| All items vs euro area | +0.86 | −1.82 to +1.38 | 0.14 |
| All items vs non-euro peers | +0.13 | −1.96 to +1.55 | 0.44 |

p = share of fake averages at least as large as the real one (10,000 random draws of one fake date per adopter).

![Placebo test: services, average of six adoptions vs the distribution of fake adoption dates](img/placebo_services.png)

Croatia on its own: services +1.8 against the euro area (p ≈ 0.07) and +0.3 against the peers (p ≈ 0.37).
Neighbouring fake dates share most of their data, so the p-values are a guide rather than exact.

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

[`powerbi/EuroPrices.pbip`](../powerbi/) (Power BI Project format: the model is TMDL and the report is PBIR,
so both are plain text and diff cleanly in git). Five pages:

| Page | Question |
|---|---|
| **Start here** | What is compared, what each page shows, how to read the filters |
| **Croatia vs control** | What happened to prices around adoption, for one adopter against one control? |
| **All adopters** | Does the same pattern repeat in every adoption? (small multiples) |
| **Robustness** | Does the result survive a different control? (adopter × control matrix) |
| **Croatia by category** | Which prices pulled away, and which of those are false alarms? |

Slicers pick the adopter, the control, the **trend window** (±12 to ±48 months) and the category
(all items, core inflation, services, goods, food, energy, non-energy industrial goods); the last page
goes down to ~140 detailed categories. Measures are window-aware DAX (`SELECTEDVALUE`, `CALCULATE`,
`AVERAGEX`) with 12-month trailing averages to remove seasonality, and always evaluate exactly one category.

**Try it without a database:** download `EuroPrices.pbix` (data included) from the
[latest release](https://github.com/ivanbelak/euro-adoption-prices/releases/latest) and open it in the free
[Power BI Desktop](https://www.microsoft.com/power-platform/products/power-bi/desktop) (Windows).
The project files in `powerbi/` hold the report and model only; with them, build the database first
(see *Running it*) and click **Refresh**.

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
| Extract | Full Eurostat `prc_hicp_minr` dataset (46 countries, 555 categories, 1996–2026) via the Eurostat API; US CPI from FRED | [`src/fetch_eurostat.py`](../src/fetch_eurostat.py), [`src/fetch_fred.py`](../src/fetch_fred.py) |
| Load | Staging and dimension tables, ~5.5M rows in ~30 s | [`src/load_sql.py`](../src/load_sql.py) |
| Transform | Star schema in SQL: pivot units, build calendar, category hierarchy | [`sql/01`–`04`](../sql/) |
| Validate | Recompute inflation from the index and compare with Eurostat's published rate | [`sql/04_views.sql`](../sql/04_views.sql) (`qa.yoy_check`) |
| Event study | Align adopters, rebase, pair with every control (CTEs, window functions, `CROSS JOIN`) | [`sql/05_event_study.sql`](../sql/05_event_study.sql) |
| Pre-trends | OLS slope of excess before adoption for four windows; trend-adjusted excess | [`sql/07_pre_trends.sql`](../sql/07_pre_trends.sql) |
| Explore | Queries behind the findings above | [`sql/06_event_study_findings.sql`](../sql/06_event_study_findings.sql) |
| Placebo test | The event study in pandas for any date, run for every fake adoption date the data allows (38 to 223 per adopter); checked against the SQL views to 1e-14 | [`src/event_study.py`](../src/event_study.py), [`notebooks/01_placebo_test.ipynb`](../notebooks/01_placebo_test.ipynb) |

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
python notebooks/build_placebo_notebook.py   # re-runs the placebo test notebook
```

Then open `powerbi/EuroPrices.pbip` in Power BI Desktop and click **Refresh** (the server and database
are Power Query parameters, `SQL Server` and `SQL Database`).

## Data sources

- **Eurostat**, Harmonised Index of Consumer Prices, dataset
  [`prc_hicp_minr`](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table) (© European Union,
  reused under Eurostat's copyright policy).
- **U.S. Bureau of Labor Statistics**, CPI for all urban consumers, not seasonally adjusted
  ([`CPIAUCNS`](https://fred.stlouisfed.org/series/CPIAUCNS), via FRED).
