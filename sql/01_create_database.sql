-- Creates the EuroPrices database (safe to run repeatedly).
IF DB_ID('EuroPrices') IS NULL
    CREATE DATABASE EuroPrices;
GO

-- Simple recovery: this is an analytics database rebuilt from source,
-- so we don't need point-in-time restore or a growing transaction log.
ALTER DATABASE EuroPrices SET RECOVERY SIMPLE;
GO
