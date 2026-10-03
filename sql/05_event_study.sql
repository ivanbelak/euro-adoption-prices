-- Event study: prices around euro adoption, relative to a control group.
--
-- Every euro adopter is aligned on its own adoption month (event_month = 0),
-- prices are rebased to 100 in the month before adoption (event_month = -1),
-- and the same rebasing is applied to the control group (EA19) over the same
-- calendar months. excess = adopter - control, in index points.
--
-- Example: Croatia, restaurants and cafes (CP111), event_month = 11 (Dec 2023):
--   index_rel = 113.4, control_rel = 105.4, excess = 8.0
--
-- Exploration queries on top of this view: 06_event_study_findings.sql

USE EuroPrices;
GO

CREATE OR ALTER VIEW pbi.event_study AS
WITH

-- STEP 1: adopters only, +-24 months around adoption
events AS (
    SELECT
        h.*,
        c.euro_adoption_date,
        DATEDIFF(month, c.euro_adoption_date, h.month_date) AS event_month
    FROM fact.hicp_monthly h
    INNER JOIN dim.country c
        ON h.country_code = c.country_code
    -- WHERE runs before SELECT, so the event_month alias can't be used here
    WHERE DATEDIFF(month, c.euro_adoption_date, h.month_date) BETWEEN -24 AND 24
      AND c.euro_adoption_date IS NOT NULL
),

-- STEP 2: rebase each country x category to 100 at event_month = -1.
-- The CASE picks the single base-month row; MAX ... OVER copies its value
-- to every row of the same country x category without collapsing rows.
rebased AS (
    SELECT
        country_code, coicop_code, event_month, month_date, index_2015,
        MAX(CASE WHEN event_month = -1 THEN index_2015 END)
            OVER (PARTITION BY country_code, coicop_code) AS base_index,
        MAX(CASE WHEN event_month = -1 THEN month_date END)
            OVER (PARTITION BY country_code, coicop_code) AS base_month
    FROM events
),

-- STEP 3: add the EA19 control, rebased to the adopter's base month.
-- EA19 is joined twice: once for the current month, once for the base month.
-- LEFT JOINs keep adopter rows even where EA19 has no data for a category.
with_control AS (
    SELECT
        r.country_code,
        r.coicop_code,
        r.event_month,
        r.month_date,
        100.0 * r.index_2015   / r.base_index          AS index_rel,    -- adopter / adopter base
        100.0 * ctl.index_2015 / ctl_base.index_2015   AS control_rel   -- EA19 / EA19 base
    FROM rebased r
    -- EA19, same category, same calendar month as the adopter's row
    LEFT JOIN fact.hicp_monthly ctl
        ON  ctl.country_code = 'EA19'
        AND ctl.coicop_code  = r.coicop_code
        AND ctl.month_date   = r.month_date
    -- EA19, same category, in the adopter's base month
    LEFT JOIN fact.hicp_monthly ctl_base
        ON  ctl_base.country_code = 'EA19'
        AND ctl_base.coicop_code  = r.coicop_code
        AND ctl_base.month_date   = r.base_month
)

SELECT
    country_code, coicop_code, event_month, month_date,
    index_rel,
    control_rel,
    index_rel - control_rel AS excess
FROM with_control;
GO
