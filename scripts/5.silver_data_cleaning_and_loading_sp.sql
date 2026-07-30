create or alter procedure silver.load_silver as
begin
	begin try
	------------------------- 1. Data Cleaning for bronze.crm_cust_info Table --------------------------
	print '>>> Truncating Table silver.crm_cust_info'
	truncate table silver.crm_cust_info
	print '>>> Inserting Data into Table: silver.crm_cust_info'

	insert into silver.crm_cust_info (cst_id,cst_key,cst_firstname,cst_lastname,cst_gndr,cst_marital_status,cst_create_date)
	select 
		cst_id,
		cst_key,
		trim(cst_firstname) as cst_firstname,
		trim(cst_lastname) as cst_lastname,
		case when upper(trim(cst_gndr)) = 'F' then 'Female'
			 when upper(trim(cst_gndr)) = 'M' then 'Male'
			 else 'Unknown'
		end  cst_gndr,
		case when upper(trim(cst_marital_status)) = 'S' then 'Single'
			 when upper(trim(cst_marital_status)) = 'M' then 'Married'
			 else 'Unknown'
		end  cst_marital_status,
		cst_create_date
	from 
		(
			select 
			*,
			row_number() over(partition by cst_id order by cst_create_date) as flag_last
			from bronze.crm_cust_info
		) as t
	where flag_last = 1 and cst_id is not null and cst_key is not null;

	------------------------- 2. Data Cleaning for bronze.crm_prd_info Table --------------------------
	--alter table silver.crm_prd_info
	--alter column prd_start_dt date;

	--alter table silver.crm_prd_info
	--alter column prd_end_dt date;

	--alter table silver.crm_prd_info
	--add cat_id nvarchar(50);

	print '>>> Truncating Table silver.crm_prd_info'
	truncate table silver.crm_prd_info
	print '>>> Inserting Data into Table: silver.crm_prd_info'

	insert into silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
	select prd_id,
		   --prd_key,
		   replace(substring(prd_key,1,5),'-','_') as cat_id,
		   substring(prd_key,7,len(prd_key)) as prd_key,
		   prd_nm,
		   isnull(prd_cost,0) as prd_cost,
		   case upper(trim(prd_line))
					when 'R' then 'Road'
					when 'S' then 'Other Sales'
					when 'M' then 'Mountain'
					when 'T' then 'Touring'
					else 'Unknown'
			end as prd_line,
		   cast(prd_start_dt as date) as prd_start_dt,
		   cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt )-1 as date) as prd_end_dt
	from bronze.crm_prd_info;

	------------------------- 3. Data Cleaning for bronze.crm_sales_details Table --------------------------
	/*
	if object_id('silver.crm_sales_details','U') is not null
		drop table silver.crm_sales_details;
	go
	create table silver.crm_sales_details (
		sls_ord_num nvarchar(50),
		sls_prd_key nvarchar(50),
		sls_cust_id int,
		sls_order_dt date,
		sls_ship_dt date,
		sls_due_dt date,
		sls_sales int,
		sls_quantity int,
		sls_price int,
		dwh_create_date datetime2 default getdate()
	);
	go
	*/

	print '>>> Truncating Table silver.crm_sales_details'
	truncate table silver.crm_sales_details
	print '>>> Inserting Data into Table: silver.crm_sales_details'

	insert into silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
	select
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
			 else cast(cast(sls_order_dt as varchar) as date)
		end as sls_order_dt,
		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
			 else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
			 else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price) then sls_quantity * abs(sls_price)
			else sls_sales
		end as sls_sales,
		sls_quantity,
		sls_price
	from bronze.crm_sales_details;
	
	--select * from silver.crm_sales_details;

	------------------------- 4. Data Cleaning for bronze.erp_cust_az12 Table --------------------------
	print '>>> Truncating Table silver.erp_cust_az12'
	truncate table silver.erp_cust_az12
	print '>>> Inserting Data into Table: silver.erp_cust_az12'

	insert into silver.erp_cust_az12 (cid,bdate,gen)
	select 
		   case 
				when cid like 'NAS%' then substring(cid,4, len(cid))
				else cid
			end as cid,
			case when bdate > getdate() then null
				 else bdate
			end as bdate,
			case when upper(trim(gen)) in ('M','MALE') then 'Male'
				 when upper(trim(gen)) in ('F','FEMALE') then 'Female'
				 else 'Unknown'
		   end as gen
	from bronze.erp_cust_az12;

	--select * from silver.erp_cust_az12;

	------------------------- 5. Data Cleaning for bronze.erp_loc_a101 Table --------------------------
	print '>>> Truncating Table silver.erp_loc_a101'
	truncate table silver.erp_loc_a101
	print '>>> Inserting Data into Table: silver.erp_loc_a101'

	insert into silver.erp_loc_a101(cid,cntry)
	select replace(cid,'-','') as cid,
		   case
			   when trim(cntry) = 'DE' then 'Germany'
			   when trim(cntry) in ('US','USA') then 'United States'
			   when trim(cntry) = '' or cntry is null then 'Unknown'
			   else trim(cntry)
		   end as cntry
	from bronze.erp_loc_a101;

	--select * from silver.erp_loc_a101;

	------------------------- 6. Data Cleaning for bronze.erp_px_cat_g1v2 Table --------------------------
	print '>>> Truncating Table silver.erp_px_cat_g1v2'
	truncate table silver.erp_px_cat_g1v2
	print '>>> Inserting Data into Table: silver.erp_px_cat_g1v2'

	insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
	select id,
		   cat,
		   subcat,
		   maintenance
	from bronze.erp_px_cat_g1v2;

	--select * from silver.erp_px_cat_g1v2;
    	end try
	begin catch
		print '=================================================';
		print 'Error Occured During Bronze Layer Loading'
		print 'Error Message: ' + error_message();
		print 'Error Number: ' + cast(error_number() as nvarchar);
		print 'Error State: ' + cast(error_state() as nvarchar);
	end catch
end ;

select * from sys.procedures where name = 'load_silver';

exec silver.load_silver;
