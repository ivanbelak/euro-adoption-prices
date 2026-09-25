-- Views. Power BI only reads from the pbi schema, so the tables
-- underneath can change without breaking the report.

USE EuroPrices;
GO

CREATE OR ALTER VIEW pbi.country AS
SELECT country_code, country_name, country_group, euro_adoption_date,
       is_aggregate, sort_order
FROM dim.country;
GO

CREATE OR ALTER VIEW pbi.category AS
SELECT c.coicop_code, c.category_name, c.category_level,
       c.parent_code, p.category_name AS parent_name, c.is_special_aggregate
FROM dim.category AS c
LEFT JOIN dim.category AS p ON p.coicop_code = c.parent_code;
GO

CREATE OR ALTER VIEW pbi.calendar AS
SELECT month_date, [year], [month], [quarter], month_name, year_month
FROM dim.calendar;
GO

CREATE OR ALTER VIEW pbi.hicp AS
SELECT country_code, coicop_code, month_date,
       index_2015, rate_yoy, rate_mom, is_flagged
FROM fact.hicp_monthly;
GO

-- US CPI with year-over-year change computed from the index.
-- The LAG guard makes sure we really compare with the same month
-- a year earlier (and not just "12 rows back" if a month were missing).
CREATE OR ALTER VIEW pbi.us_cpi AS
SELECT
    month_date,
    cpi_u_nsa,
    CASE
        WHEN LAG(month_date, 12) OVER (ORDER BY month_date) = DATEADD(month, -12, month_date)
        THEN CAST(ROUND(100.0 * (cpi_u_nsa / LAG(cpi_u_nsa, 12) OVER (ORDER BY month_date) - 1), 2)
                  AS decimal(8,2))
    END AS rate_yoy
FROM ref.us_cpi;
GO

-- QA: recompute the year-over-year rate from the index and compare it
-- with the rate Eurostat publishes. Big differences point to breaks in
-- the series or loading errors.
CREATE OR ALTER VIEW qa.yoy_check AS
WITH x AS (
    SELECT
        country_code, coicop_code, month_date, index_2015, rate_yoy,
        LAG(index_2015, 12) OVER (PARTITION BY country_code, coicop_code ORDER BY month_date) AS index_prev_year,
        LAG(month_date, 12) OVER (PARTITION BY country_code, coicop_code ORDER BY month_date) AS month_prev_year
    FROM fact.hicp_monthly
)
-- NULLIF guards the division: SQL Server may evaluate the SELECT list
-- before the WHERE filter, so "WHERE index_prev_year > 0" alone isn't enough.
SELECT
    country_code, coicop_code, month_date,
    rate_yoy AS published_yoy,
    CAST(ROUND(100.0 * (index_2015 / NULLIF(index_prev_year, 0) - 1), 2) AS decimal(8,2)) AS computed_yoy,
    ABS(rate_yoy - 100.0 * (index_2015 / NULLIF(index_prev_year, 0) - 1)) AS abs_diff
FROM x
WHERE month_prev_year = DATEADD(month, -12, month_date)
  AND index_prev_year > 0
  AND rate_yoy IS NOT NULL;
GO
