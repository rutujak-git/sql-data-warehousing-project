-/*
============================================================
Purpose:
    This script performs the initial setup of the data 
    warehouse environment.

    It performs the following actions:
    1. Drops the 'data_warehouse' database if it already 
       exists (ensuring a clean rebuild on every run).
    2. Creates a fresh 'data_warehouse' database.
    3. Creates three schemas within the database that 
       represent the Medallion Architecture layers:
         - bronze : raw, unprocessed source data
         - silver : cleaned & standardized data
         - gold   : business-ready data for reporting/analytics
============================================================
*/
-- 1. Create database 'data_warehouse'
use master;
go
-- Drop & recreate data_warehouse if already exists
-- check if a database named 'data_warehouse' already exists in the instance
if exists (select 1 from sys.databases where name = 'data_warehouse')
begin
	-- force the database into single-user mode and immediately roll back
	-- any open transactions/connections, so it can be dropped without being blocked
	alter database data_warehouse set single_user with rollback immediate;

	-- drop the existing database so it can be recreated fresh
	drop database data_warehouse;
end;
go

create database data_warehouse;

use data_warehouse;
go
-- 2. Create Schemas

create schema bronze;
go
create schema silver;
go
create schema gold;
go
