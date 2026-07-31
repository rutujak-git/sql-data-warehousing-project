# SQL Data Warehouse from Scratch

A SQL Server data warehouse built end-to-end using the Medallion Architecture (Bronze → Silver → Gold). Raw CRM and ERP data is ingested from CSV files, cleaned and standardized, then modeled into a star schema ready for reporting and analytics.

## Architecture

<img width="688" height="376" alt="image" src="https://github.com/user-attachments/assets/28f7ea7d-a961-4375-a0c0-5f908f4611f8" />


The pipeline follows a standard ETL pattern — extract from source files, transform through cleaning rules, load into structured tables.

This project uses the **Medallion Architecture**, one of several common data warehouse design approaches (others include Inmon, Kimball, and Data Vault).


<img width="732" height="350" alt="image" src="https://github.com/user-attachments/assets/2d56756b-4663-4782-880c-5ed11590f757" />



| Layer | Purpose | Object Type |
|---|---|---|
| **Bronze** | Raw data, as-is from source | Tables |
| **Silver** | Cleaned and standardized data | Tables |
| **Gold** | Business-ready data for reporting | Views |

### Why Medallion Over the Other Approaches

| Approach | Advantages | Disadvantages |
|---|---|---|
| **Inmon** | Single, highly normalized (3NF) enterprise-wide data warehouse — consistent, non-redundant, single source of truth across the whole business | Slow and complex to build; querying requires many joins across normalized tables, which hurts reporting performance; changes to the model are harder to make |
| **Kimball** | Dimensional model (star schema) built directly for reporting — fast to build, easy to query, intuitive for business users | No separate enterprise-wide integration layer; if requirements change, rebuilding data marts can duplicate effort and cause inconsistency across marts |
| **Data Vault** | Highly flexible and auditable — Raw Vault preserves full history and source lineage, Business Vault adds business rules without touching raw data; scales well with frequently changing sources | Adds extra modeling layers (Hubs, Links, Satellites) that increase complexity; still needs a further step (Data Marts) before it's usable for reporting |
| **Medallion (Bronze/Silver/Gold)** | Combines the strengths of the above: Bronze preserves raw history and traceability (like Data Vault's Raw Vault), Silver applies standardization and cleaning once for all downstream use (avoiding Kimball's duplicated mart logic), and Gold delivers a dimensional star schema for fast, simple reporting (Kimball's strength) — without Inmon's heavy 3NF modeling overhead | Less formalized/standardized than the other three (no strict theoretical model to follow); relies on team discipline to keep layer responsibilities clean, since there's no rigid structure enforcing it |

In short: Medallion takes Data Vault's idea of keeping raw, traceable history, skips Inmon's costly full normalization, and still lands on a Kimball-style star schema at the end — giving both auditability and fast reporting without needing two separate systems to get there.

## Data Sources

| System | Files | What it contains |
|---|---|---|
| CRM | `cust_info`, `prd_info`, `sales_details` | Customer info, product info, sales transactions |
| ERP | `CUST_AZ12`, `LOC_A101`, `PX_CAT_G1V2` | Customer birthdate/gender, customer country, product category |

## Repository Structure

```
sql-dw-scratch/
├── datasets/
│   ├── source_crm/
│   └── source_erp/
├── scripts/
│   ├── bronze/
│   ├── silver/
│   └── gold/
└── README.md
```

## Bronze Layer — Raw Tables

Raw data loaded exactly as received, with no transformation. Purpose: traceability and debugging back to source.

**`bronze.crm_cust_info`**
| Column | Type |
|---|---|
| cst_id | int |
| cst_key | nvarchar(50) |
| cst_firstname | nvarchar(50) |
| cst_lastname | nvarchar(50) |
| cst_marital_status | nvarchar(50) |
| cst_gndr | nvarchar(50) |
| cst_create_date | date |

**`bronze.crm_prd_info`**
| Column | Type |
|---|---|
| prd_id | int |
| prd_key | nvarchar(50) |
| prd_nm | nvarchar(50) |
| prd_cost | int |
| prd_line | nvarchar(50) |
| prd_start_dt | datetime |
| prd_end_dt | datetime |

**`bronze.crm_sales_details`**
| Column | Type |
|---|---|
| sls_ord_num | nvarchar(50) |
| sls_prd_key | nvarchar(50) |
| sls_cust_id | int |
| sls_order_dt | int |
| sls_ship_dt | int |
| sls_due_dt | int |
| sls_sales | int |
| sls_quantity | int |
| sls_price | int |

**`bronze.erp_cust_az12`**
| Column | Type |
|---|---|
| cid | nvarchar(50) |
| bdate | date |
| gen | nvarchar(50) |

**`bronze.erp_loc_a101`**
| Column | Type |
|---|---|
| cid | nvarchar(50) |
| cntry | nvarchar(50) |

**`bronze.erp_px_cat_g1v2`**
| Column | Type |
|---|---|
| id | nvarchar(50) |
| cat | nvarchar(50) |
| subcat | nvarchar(50) |
| maintenance | nvarchar(50) |

Loaded via the `bronze.load_bronze` stored procedure, using `BULK INSERT` with a full truncate-and-reload pattern.

## Silver Layer — Cleaned Tables

Same tables as Bronze, with cleaning and standardization applied. Key changes:

- Trimmed whitespace from text fields
- Standardized coded values into readable labels (e.g. `F`/`M` → `Female`/`Male`)
- Removed duplicate customer records, keeping the most recent
- Converted `YYYYMMDD` integer dates into proper `date` type
- Recalculated sales amount where missing, negative, or inconsistent with quantity × price
- Standardized country names (e.g. `DE` → `Germany`)
- Added `cat_id` to `crm_prd_info`, linking each product to its category
- Added `dwh_create_date` to every table, tracking when the row was loaded

Loaded via the `silver.load_silver` stored procedure, same truncate-and-reload pattern as Bronze.

## Gold Layer — Star Schema (Views)

Business-ready views, built by joining Silver tables together. No load step — views calculate results live each time they're queried.

**`gold.dim_customers`**
| Column | Type | Source |
|---|---|---|
| customer_key | int | generated (surrogate key) |
| customer_id | int | crm_cust_info.cst_id |
| customer_number | nvarchar(50) | crm_cust_info.cst_key |
| first_name | nvarchar(50) | crm_cust_info.cst_firstname |
| last_name | nvarchar(50) | crm_cust_info.cst_lastname |
| country | nvarchar(50) | erp_loc_a101.cntry |
| marital_status | nvarchar(50) | crm_cust_info.cst_marital_status |
| gender | nvarchar(50) | crm_cust_info / erp_cust_az12 |
| birthdate | date | erp_cust_az12.bdate |
| create_date | date | crm_cust_info.cst_create_date |

**`gold.dim_product`**
| Column | Type | Source |
|---|---|---|
| product_key | int | generated (surrogate key) |
| product_id | int | crm_prd_info.prd_id |
| product_number | nvarchar(50) | crm_prd_info.prd_key |
| product_name | nvarchar(50) | crm_prd_info.prd_nm |
| category_id | nvarchar(50) | crm_prd_info.cat_id |
| category | nvarchar(50) | erp_px_cat_g1v2.cat |
| subcategory | nvarchar(50) | erp_px_cat_g1v2.subcat |
| maintenance | nvarchar(50) | erp_px_cat_g1v2.maintenance |
| cost | int | crm_prd_info.prd_cost |
| product_line | nvarchar(50) | crm_prd_info.prd_line |
| start_date | date | crm_prd_info.prd_start_dt |

Filtered to current products only (`prd_end_dt is null`).

**`gold.fact_sales`**
| Column | Type | Source |
|---|---|---|
| order_number | nvarchar(50) | crm_sales_details.sls_ord_num |
| product_key | int | joined from dim_product |
| customer_key | int | joined from dim_customers |
| order_date | date | crm_sales_details.sls_order_dt |
| shipping_date | date | crm_sales_details.sls_ship_dt |
| due_date | date | crm_sales_details.sls_due_dt |
| sales_amount | int | crm_sales_details.sls_sales |
| quantity | int | crm_sales_details.sls_quantity |
| price | int | crm_sales_details.sls_price |

## Data Model (Star Schema)

<img width="534" height="254" alt="image" src="https://github.com/user-attachments/assets/f065fd61-1afc-4dae-a326-ab600667fb7f" />

`gold.fact_sales` sits at the center, joined to `gold.dim_customers` and `gold.dim_product` through their surrogate keys.

<img width="702" height="380" alt="image" src="https://github.com/user-attachments/assets/54e6b4fa-9f25-4e95-8aec-4021627c6bfb" />


## How to Run

1. Run `2_database_and_schemas_creation.sql` — creates the `data_warehouse` database and the `bronze`/`silver`/`gold` schemas.
2. Run `1_bronze_tables_creation.sql` — creates the Bronze layer tables.
3. Update the file paths in `3_bronze_tables_loading.sql` to point to your local `datasets/` folder, then run it to create and execute `bronze.load_bronze`.
4. Run `4_silver_tables_creation.sql` — creates the Silver layer tables.
5. Run `5_silver_data_cleaning_sp.sql` — creates and executes `silver.load_silver`, which cleans and loads Bronze data into Silver.
6. Run `6_gold_data_modeling.sql` — creates the Gold layer views.

## Key Decisions

- **Gold layer uses views, not tables** — always reflects the latest Silver data with no separate load step needed.
- **Surrogate keys via `ROW_NUMBER()`** — views can't use `IDENTITY` columns, so `ROW_NUMBER()` over a fixed order generates sequential keys instead.
- **Int-to-date conversion** — sales dates arrive as `YYYYMMDD` integers; SQL Server can't convert `int` directly to `date`, so they're cast to `varchar` first, then `date`.
- **Category join uses `cat_id`, not `prd_id`** — `prd_id` is just the internal product ID; `cat_id` is the derived code that actually matches the ERP category table.
