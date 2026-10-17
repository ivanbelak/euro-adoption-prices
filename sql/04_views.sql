-- Views. Power BI only reads from the pbi schema, so the tables
-- underneath can change without breaking the report.

USE EuroPrices;
GO

CREATE OR ALTER VIEW pbi.country AS
SELECT country_code, country_name, country_group, euro_adoption_date,
       is_aggregate, sort_order
FROM dim.country;
GO

-- Categories, plus columns for a two-step picker in Power BI:
-- category_group (14 options) narrows category_label to one group.
-- Only meaningful categories get a group (in_slicer = 1): a curated list of
-- Eurostat aggregates, and COICOP levels 1-3. Levels 4-5 are left out because
-- the controls only have them from 2014-2016 on.
CREATE OR ALTER VIEW pbi.category AS
WITH headline AS (
    SELECT * FROM (VALUES
        ('TOTAL',          'All items',                                 1),
        ('TOT_X_NRG_FOOD', 'Core inflation (excl. energy, food, alcohol, tobacco)', 2),
        ('SERV',           'Services',                                  3),
        ('GD',             'Goods',                                     4),
        ('FOOD',           'Food, alcohol and tobacco',                 5),
        ('NRG',            'Energy',                                    6),
        ('IGD_NNRG',       'Non-energy industrial goods',               7),
        ('FOOD_P',         'Processed food',                            8),
        ('FOOD_NP',        'Unprocessed food',                          9),
        ('TOT_X_NRG',      'All items excl. energy',                   10),
        ('AP',             'Administered prices',                      11),
        ('TOT_X_AP',       'All items excl. administered prices',      12),
        ('SERV_REC',       'Services: recreation and personal care',   13),
        ('SERV_TRA',       'Services: transport',                      14),
        ('SERV_HOUS',      'Services: housing',                        15),
        ('SERV_COM',       'Services: communication',                  16),
        ('SERV_MSC',       'Services: miscellaneous',                  17)
    ) AS h (coicop_code, short_name, sort_no)
),
labelled AS (
    SELECT
        c.coicop_code, c.category_name, c.category_level,
        c.parent_code, p.category_name AS parent_name, c.is_special_aggregate,
        CASE
            WHEN h.coicop_code IS NOT NULL THEN 'Headline indicators'
            WHEN c.category_level BETWEEN 1 AND 3
                THEN SUBSTRING(c.coicop_code, 3, 2) + ' ' + d.category_name
        END AS category_group,
        CASE
            WHEN h.coicop_code IS NOT NULL THEN 0
            WHEN c.category_level BETWEEN 1 AND 3 THEN CAST(SUBSTRING(c.coicop_code, 3, 2) AS int)
        END AS category_group_sort,
        -- "11.1.1 Restaurants, cafes ..." shows where a category sits in COICOP
        CASE
            WHEN h.coicop_code IS NOT NULL THEN h.short_name
            WHEN c.category_level = 1 THEN SUBSTRING(c.coicop_code, 3, 2) + ' ' + c.category_name
            WHEN c.category_level = 2 THEN SUBSTRING(c.coicop_code, 3, 2) + '.' + SUBSTRING(c.coicop_code, 5, 1)
                                           + ' ' + c.category_name
            WHEN c.category_level = 3 THEN SUBSTRING(c.coicop_code, 3, 2) + '.' + SUBSTRING(c.coicop_code, 5, 1)
                                           + '.' + SUBSTRING(c.coicop_code, 6, 1) + ' ' + c.category_name
        END AS category_label,
        -- headline indicators first, in the order above, then COICOP order
        CASE WHEN h.coicop_code IS NOT NULL THEN FORMAT(h.sort_no, '000') ELSE c.coicop_code END AS category_label_sort
    FROM dim.category AS c
    LEFT JOIN dim.category AS p ON p.coicop_code = c.parent_code
    LEFT JOIN dim.category AS d ON d.coicop_code = LEFT(c.coicop_code, 4)   -- the COICOP division (CP01..CP13)
    LEFT JOIN headline AS h ON h.coicop_code = c.coicop_code
)
SELECT *,
       CAST(CASE WHEN category_group IS NOT NULL THEN 1 ELSE 0 END AS bit) AS in_slicer
FROM labelled;
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
