-- Schemas and tables. Drops and recreates everything: the database is
-- fully rebuilt from the downloaded files on every load.
--
--   stg   raw data as loaded from Python (long format, one row per unit)
--   dim   dimension tables (who / what / when)
--   fact  measurements, one row per country x category x month
--   ref   external reference series (US CPI)
--   pbi   views that Power BI reads (see 04_views.sql)
--   qa    data quality checks

USE EuroPrices;
GO

IF SCHEMA_ID('stg')  IS NULL EXEC('CREATE SCHEMA stg');
IF SCHEMA_ID('dim')  IS NULL EXEC('CREATE SCHEMA dim');
IF SCHEMA_ID('fact') IS NULL EXEC('CREATE SCHEMA fact');
IF SCHEMA_ID('ref')  IS NULL EXEC('CREATE SCHEMA ref');
IF SCHEMA_ID('pbi')  IS NULL EXEC('CREATE SCHEMA pbi');
IF SCHEMA_ID('qa')   IS NULL EXEC('CREATE SCHEMA qa');
GO

DROP TABLE IF EXISTS fact.hicp_monthly;
DROP TABLE IF EXISTS stg.hicp;
DROP TABLE IF EXISTS stg.us_cpi;
DROP TABLE IF EXISTS dim.country;
DROP TABLE IF EXISTS dim.category;
DROP TABLE IF EXISTS dim.calendar;
DROP TABLE IF EXISTS ref.us_cpi;
GO

CREATE TABLE stg.hicp (
    country_code varchar(12)   NOT NULL,
    coicop_code  varchar(20)   NOT NULL,
    unit         varchar(12)   NOT NULL,  -- I15 = index 2015=100, RCH_A = yoy %, RCH_M = mom %
    month_date   date          NOT NULL,
    value        decimal(12,4) NOT NULL,
    flag         varchar(4)    NOT NULL   -- Eurostat flag, '' if none
);

CREATE TABLE stg.us_cpi (
    month_date date          NOT NULL,
    cpi_u_nsa  decimal(10,3) NOT NULL
);

CREATE TABLE dim.country (
    country_code       varchar(12)   NOT NULL PRIMARY KEY,
    country_name       nvarchar(100) NOT NULL,
    country_group      nvarchar(50)  NOT NULL,
    euro_adoption_date date          NULL,
    is_aggregate       bit           NOT NULL,
    sort_order         int           NOT NULL
);

CREATE TABLE dim.category (
    coicop_code          varchar(20)   NOT NULL PRIMARY KEY,
    category_name        nvarchar(200) NOT NULL,
    category_level       tinyint       NULL,  -- 0 = total, 1 = division (CP01) ... 5; NULL for special aggregates
    parent_code          varchar(20)   NULL,
    is_special_aggregate bit           NOT NULL  -- e.g. SERV (services), NRG (energy)
);

CREATE TABLE dim.calendar (
    month_date  date       NOT NULL PRIMARY KEY,
    [year]      smallint   NOT NULL,
    [month]     tinyint    NOT NULL,
    [quarter]   tinyint    NOT NULL,
    month_name  varchar(9) NOT NULL,
    year_month  char(7)    NOT NULL
);

CREATE TABLE fact.hicp_monthly (
    country_code varchar(12)   NOT NULL REFERENCES dim.country (country_code),
    coicop_code  varchar(20)   NOT NULL REFERENCES dim.category (coicop_code),
    month_date   date          NOT NULL REFERENCES dim.calendar (month_date),
    index_2015   decimal(12,4) NULL,
    rate_yoy     decimal(8,2)  NULL,
    rate_mom     decimal(8,2)  NULL,
    is_flagged   bit           NOT NULL,  -- any Eurostat flag on any of the three values
    CONSTRAINT pk_hicp_monthly PRIMARY KEY (country_code, coicop_code, month_date)
);

CREATE TABLE ref.us_cpi (
    month_date date          NOT NULL PRIMARY KEY,
    cpi_u_nsa  decimal(10,3) NOT NULL
);
GO
