-- Exploration queries on pbi.event_study (see 05_event_study.sql).
-- Not part of the build: run them one at a time in SSMS.
--
-- The view has one row per control (control_code = EA19, HU, PL, CZ, RO),
-- so every query either filters on one control or compares them side by side.

USE EuroPrices;
GO

-- 1. Did the euro raise overall prices? Excess for the whole basket,
--    one year after adoption, against EA19.
--    (Bulgaria is missing: data only reaches its event_month 7.)
SELECT country_code, excess
FROM pbi.event_study
WHERE coicop_code = 'TOTAL'
  AND control_code = 'EA19'
  AND event_month = 11
ORDER BY excess DESC;

-- 2. Which Croatian categories pulled furthest away from EA19?
--    Flip DESC to ASC for the ones that rose more slowly.
--    Large values need checking before reading them as a euro effect:
--    passenger transport is driven by Germany's Deutschlandticket
--    (May 2023), electricity and gas by Croatian price caps.
SELECT TOP 10
    e.coicop_code,
    cat.category_name,
    e.index_rel   AS hr,
    e.control_rel AS ea19,
    e.excess
FROM pbi.event_study e
INNER JOIN dim.category cat
    ON e.coicop_code = cat.coicop_code
WHERE e.country_code = 'HR'
  AND e.control_code = 'EA19'
  AND e.event_month = 11
  AND cat.category_level = 3      -- mid-level detail, e.g. "Electricity", "Restaurants"
  AND e.excess IS NOT NULL
ORDER BY e.excess DESC;

-- 3. The path over time: restaurants and cafes in Croatia vs EA19,
--    -24 to +24 months.
SELECT event_month, month_date, index_rel, control_rel, excess
FROM pbi.event_study
WHERE country_code = 'HR'
  AND coicop_code = 'CP111'
  AND control_code = 'EA19'
ORDER BY event_month;

-- 4. Is the effect concentrated in services? Eurostat special aggregates,
--    one year after adoption, against EA19.
SELECT
    country_code,
    MAX(CASE WHEN coicop_code = 'TOTAL'    THEN excess END) AS total,
    MAX(CASE WHEN coicop_code = 'TOT_X_AP' THEN excess END) AS total_excl_administered,
    MAX(CASE WHEN coicop_code = 'SERV'     THEN excess END) AS services,
    MAX(CASE WHEN coicop_code = 'FOOD'     THEN excess END) AS food
FROM pbi.event_study
WHERE event_month = 11
  AND control_code = 'EA19'
GROUP BY country_code
ORDER BY services DESC;

-- 5. Robustness: does the services result survive a different control?
--    One column per control. A real euro effect should be positive
--    against most of them, not only against EA19.
SELECT
    country_code,
    MAX(CASE WHEN control_code = 'EA19' THEN excess END) AS vs_ea19,
    MAX(CASE WHEN control_code = 'HU'   THEN excess END) AS vs_hu,
    MAX(CASE WHEN control_code = 'PL'   THEN excess END) AS vs_pl,
    MAX(CASE WHEN control_code = 'CZ'   THEN excess END) AS vs_cz,
    MAX(CASE WHEN control_code = 'RO'   THEN excess END) AS vs_ro
FROM pbi.event_study
WHERE coicop_code = 'SERV'
  AND event_month = 11
GROUP BY country_code
ORDER BY country_code;

-- 6. Data check: where is the price index exactly 0? Dividing by these
--    broke the view before NULLIF was added. Some are real (Bulgaria made
--    kindergartens free from April 2022), some look like gaps in the data.
SELECT h.country_code, h.coicop_code, cat.category_name,
       MIN(h.month_date) AS first_zero, MAX(h.month_date) AS last_zero, COUNT(*) AS months
FROM fact.hicp_monthly h
INNER JOIN dim.category cat
    ON h.coicop_code = cat.coicop_code
WHERE h.index_2015 = 0
GROUP BY h.country_code, h.coicop_code, cat.category_name
ORDER BY h.country_code, h.coicop_code;

-- 7. The country groups available in dim.country (used to pick controls).
SELECT DISTINCT country_group
FROM dim.country;
