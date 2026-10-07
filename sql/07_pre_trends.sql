-- Pre-trends: was the adopter already drifting away from the control
-- before the euro?
--
-- The event study assumes "parallel trends": without the euro, adopter and
-- control would have moved alike. If excess was already rising before
-- adoption, part of the post-adoption excess is just that old trend.
--
-- For every adopter x control x category we fit a straight line through
-- excess over the last N months before adoption (ordinary least squares,
-- slope in index points per month) and extend it past adoption. excess is 0
-- at event_month = -1 by construction, so the trend's prediction for month t
-- is pre_slope * (t + 1), and
--
--     excess_detrended = excess - pre_slope * (event_month + 1)
--
-- The fit window N is a choice, and the result depends on it (Croatia's
-- 2022 inflation surge makes short windows steep), so slopes are computed
-- for N = 12, 24, 36 and 48 and the Power BI report lets you switch.
-- N = 12 covers a single tourist season and is the least reliable.

USE EuroPrices;
GO

-- One row per adopter x control x category x fit window
CREATE OR ALTER VIEW pbi.pre_trend AS
WITH windows AS (
    SELECT n FROM (VALUES (12), (24), (36), (48)) AS w (n)
),
pre AS (
    SELECT e.country_code, e.control_code, e.coicop_code, w.n AS pre_window,
           CAST(e.event_month AS float) AS x,
           CAST(e.excess AS float)      AS y
    FROM pbi.event_study e
    INNER JOIN windows w
        ON e.event_month BETWEEN -w.n AND -1
    WHERE e.excess IS NOT NULL
),
fit AS (
    -- OLS slope = (n*Sxy - Sx*Sy) / (n*Sxx - Sx^2)
    SELECT country_code, control_code, coicop_code, pre_window,
           COUNT(*) AS n_pre_months,
           (COUNT(*) * SUM(x * y) - SUM(x) * SUM(y))
               / NULLIF(COUNT(*) * SUM(x * x) - SUM(x) * SUM(x), 0) AS pre_slope
    FROM pre
    GROUP BY country_code, control_code, coicop_code, pre_window
)
SELECT
    f.country_code, f.control_code, f.coicop_code, f.pre_window,
    f.n_pre_months,
    f.pre_slope,
    m11.excess AS excess_m11,   -- excess one year after adoption
    m11.excess - f.pre_slope * 12 AS excess_m11_detrended
FROM fit f
LEFT JOIN pbi.event_study m11
    ON  m11.country_code = f.country_code AND m11.control_code = f.control_code
    AND m11.coicop_code  = f.coicop_code  AND m11.event_month  = 11
-- A slope from less than 3/4 of the window isn't trustworthy
WHERE f.n_pre_months >= 0.75 * f.pre_window;
GO

-- The event study with the pre-trend slope for every fit window as columns,
-- one row per month. This is the main table for Power BI, which picks the
-- slope that matches the window chosen in the report.
-- excess_detrended uses the 24-month window, for SQL users.
CREATE OR ALTER VIEW pbi.event_study_detrended AS
WITH slopes AS (
    SELECT country_code, control_code, coicop_code,
           MAX(CASE WHEN pre_window = 12 THEN pre_slope END) AS pre_slope_12,
           MAX(CASE WHEN pre_window = 24 THEN pre_slope END) AS pre_slope_24,
           MAX(CASE WHEN pre_window = 36 THEN pre_slope END) AS pre_slope_36,
           MAX(CASE WHEN pre_window = 48 THEN pre_slope END) AS pre_slope_48
    FROM pbi.pre_trend
    GROUP BY country_code, control_code, coicop_code
)
SELECT
    e.country_code, e.control_code, e.coicop_code, e.event_month, e.month_date,
    e.index_rel, e.control_rel, e.excess,
    s.pre_slope_12, s.pre_slope_24, s.pre_slope_36, s.pre_slope_48,
    e.excess - s.pre_slope_24 * (e.event_month + 1) AS excess_detrended
FROM pbi.event_study e
LEFT JOIN slopes s
    ON  s.country_code = e.country_code
    AND s.control_code = e.control_code
    AND s.coicop_code  = e.coicop_code;
GO
