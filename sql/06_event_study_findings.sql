-- Exploration queries on pbi.event_study (see 05_event_study.sql).
-- Not part of the build: run them one at a time in SSMS.

USE EuroPrices;
GO

-- 1. Did the euro raise overall prices? Excess for the whole basket,
--    one year after adoption, for every adopter.
--    (Bulgaria is missing: data only reaches its event_month 7.)
SELECT country_code, excess
FROM pbi.event_study
WHERE coicop_code = 'TOTAL'
  AND event_month = 11
ORDER BY excess DESC;

-- 2. Which Croatian categories pulled furthest away from the euro area?
--    Flip DESC to ASC for the ones that rose more slowly.
--    Large values need checking before reading them as a euro effect:
--    e.g. passenger transport is driven by Germany's Deutschlandticket
--    (May 2023), energy by Croatian price caps.
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
  AND e.event_month = 11
  AND cat.category_level = 3      -- mid-level detail, e.g. "Electricity", "Restaurants"
  AND e.excess IS NOT NULL
ORDER BY e.excess DESC;

-- 3. The path over time: restaurants and cafes in Croatia, -24 to +24 months.
SELECT event_month, month_date, index_rel, control_rel, excess
FROM pbi.event_study
WHERE country_code = 'HR'
  AND coicop_code = 'CP111'
ORDER BY event_month;

-- 4. Is the effect concentrated in services? Eurostat special aggregates,
--    one year after adoption, for every adopter.
SELECT
    country_code,
    MAX(CASE WHEN coicop_code = 'TOTAL'    THEN excess END) AS total,
    MAX(CASE WHEN coicop_code = 'TOT_X_AP' THEN excess END) AS total_excl_administered,
    MAX(CASE WHEN coicop_code = 'SERV'     THEN excess END) AS services,
    MAX(CASE WHEN coicop_code = 'FOOD'     THEN excess END) AS food
FROM pbi.event_study
WHERE event_month = 11
GROUP BY country_code
ORDER BY services DESC;
