-- Staging -> dimensions and facts. Runs after Python has filled
-- stg.hicp, stg.us_cpi, dim.country and dim.category.

USE EuroPrices;
GO

-- Calendar: one row per month covering all loaded data
WITH bounds AS (
    SELECT MIN(month_date) AS first_month, MAX(month_date) AS last_month
    FROM stg.hicp
),
months AS (
    SELECT first_month AS month_date, last_month FROM bounds
    UNION ALL
    SELECT DATEADD(month, 1, month_date), last_month
    FROM months
    WHERE month_date < last_month
)
INSERT INTO dim.calendar (month_date, [year], [month], [quarter], month_name, year_month)
SELECT
    month_date,
    YEAR(month_date),
    MONTH(month_date),
    DATEPART(quarter, month_date),
    DATENAME(month, month_date),
    FORMAT(month_date, 'yyyy-MM')
FROM months
OPTION (MAXRECURSION 1000);
GO

-- Pivot the three units from long (one row per unit) to wide (one column per unit)
INSERT INTO fact.hicp_monthly
    (country_code, coicop_code, month_date, index_2015, rate_yoy, rate_mom, is_flagged)
SELECT
    s.country_code,
    s.coicop_code,
    s.month_date,
    MAX(CASE WHEN s.unit = 'I15'   THEN s.value END),
    MAX(CASE WHEN s.unit = 'RCH_A' THEN s.value END),
    MAX(CASE WHEN s.unit = 'RCH_M' THEN s.value END),
    MAX(CASE WHEN s.flag <> '' THEN 1 ELSE 0 END)
FROM stg.hicp AS s
GROUP BY s.country_code, s.coicop_code, s.month_date;
GO

INSERT INTO ref.us_cpi (month_date, cpi_u_nsa)
SELECT month_date, cpi_u_nsa
FROM stg.us_cpi
WHERE month_date >= (SELECT MIN(month_date) FROM dim.calendar);
GO
