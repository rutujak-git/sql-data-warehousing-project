/*
============================================================
Purpose:
    This stored procedure loads data into the Bronze layer 
    from external CSV source files (CRM and ERP systems).

    It performs the following actions for each source table:
    1. Truncates the existing bronze table (full load pattern -
       all data is reloaded from source every run).
    2. Bulk inserts the corresponding CSV file into the table.
    3. Prints the load duration for each individual table, 
       as well as the total load duration for the entire 
       Bronze layer.

    Error handling is included via TRY...CATCH: if any step 
    fails, the procedure prints the error message, error 
    number, and error state instead of stopping abruptly.

Parameters:
    None. 
    This stored procedure does not accept any parameters or 
    return any values.

Usage Example:
    EXEC bronze.load_bronze;
============================================================
*/

create or alter procedure bronze.load_bronze
as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime
	begin try
		set @batch_start_time = getdate();
		print '===================================';
		print 'Loading Bronze Layer';
		print '===================================';

		print '-----------------------------------';
		print 'Loading CRM Tables';
		print '-----------------------------------';

		set @start_time = getdate();
		print '>> Truncating Table bronze.crm_cust_info';
		-- 1. table 1 - crm_cust_info load
		truncate table bronze.crm_cust_info; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.crm_cust_info';
		bulk insert bronze.crm_cust_info
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.crm_cust_info Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';

		--select * from bronze.crm_cust_info;
		--select count(*) from bronze.crm_cust_info;

		-- 2. table 2 - crm_prd_info load
		set @start_time = getdate();
		print '>> Truncating Table bronze.crm_prd_info';
		truncate table bronze.crm_prd_info; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.crm_prd_info';
		bulk insert bronze.crm_prd_info
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.crm_prd_info Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';

		--select * from bronze.crm_prd_info;

		-- 3. table 3 - crm_sales_detail load
		set @start_time = getdate();
		print '>> Truncating Table bronze.crm_sales_details';
		truncate table bronze.crm_sales_details; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.crm_sales_details';
		bulk insert bronze.crm_sales_details
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.crm_sales_details Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';
		--select * from bronze.crm_sales_details;

		print '-----------------------------------';
		print 'Loading ERP Tables';
		print '-----------------------------------';
		set @start_time = getdate();
		-- 4. table 4 - erp_cust_az12 load
		print '>> Truncating Table bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.erp_cust_az12';
		bulk insert bronze.erp_cust_az12
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.erp_cust_az12 Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';
		--select * from bronze.crm_sales_details;

		-- select * from bronze.erp_cust_az12;

		-- 5. table 5 - erp_loc_a101 load
		set @start_time = getdate();
		print '>> Truncating Table bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.erp_loc_a101';
		bulk insert bronze.erp_loc_a101
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.erp_loc_a101 Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';

		-- select * from bronze.erp_loc_a101;

		-- 6. table 6 - erp_px_cat_g1v2 load
		set @start_time = getdate();
		print '>> Inserting Data into Table bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2; -- bexause we are doing full load each time

		print '>> Inserting Data into Table bronze.erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Documents\Resume\SSIT\New Process\Projects\DataWarehouse-DataModeling\DataWarehousingProjects\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock 
		);
		set @end_time = getdate();
		print 'Load Duration for bronze.erp_px_cat_g1v2 Table: ' + cast(datediff(second,@start_time, @end_time) as varchar) + 'Seconds';
		print '----------------------------------------------------------------------------------------------';

		set @batch_end_time = getdate();
		print '==============================================================================================';
		print 'Total Load Duration For Complete Bronze Layer: ' + cast(datediff(second,@batch_start_time, @batch_end_time) as nvarchar) + 'Seconds';
		print '==============================================================================================';
--select * from bronze.erp_px_cat_g1v2;
	end try
	begin catch
		print '=================================================';
		print 'Error Occured During Bronze Layer Loading'
		print 'Error Message: ' + error_message();
		print 'Error Number: ' + cast(error_number() as nvarchar);
		print 'Error State: ' + cast(error_state() as nvarchar);
	end catch
end

-- execute stored procedure
exec bronze.load_bronze;
