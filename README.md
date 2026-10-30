
| Layer | Schema | Materialization | Objects |
| --- | --- | --- | --- |
| Raw | `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`, `ANALYTICS.RAW` | shared / table | 7 source tables, 1 loaded CSV |
| Staging | `ANALYTICS.STAGING` | view | 7 models |
| Intermediate | `ANALYTICS.INTERMEDIATE` | view | 2 models |
| Marts | `ANALYTICS.MARTS` | table (1 incremental) | 6 models + 1 snapshot |
| Consumption | — | — | 5 analysis queries |

TPC-H is read in place as a dbt source; it is never copied into `RAW`.

---

## 2. Models and grain

| Model | Grain | Built from |
| --- | --- | --- |
| `stg_tpch__customers` | one customer | `tpch.customer` |
| `stg_tpch__orders` | one order | `tpch.orders` |
| `stg_tpch__lineitems` | one order line | `tpch.lineitem` |
| `stg_tpch__parts` | one part | `tpch.part` |
| `stg_tpch__nations` | one nation | `tpch.nation` |
| `stg_tpch__regions` | one region | `tpch.region` |
| `stg_raw__region_targets` | one region per year | `raw.region_targets` |
| `int_customers_with_region` | one customer | customers → nations → regions |
| `int_order_lines_enriched` | one order line | lineitems + orders + parts + customer geography |
| `dim_customers` | one customer | `int_customers_with_region` |
| `dim_parts` | one part | `stg_tpch__parts` |
| `dim_regions` | one region | `stg_tpch__regions` + nation count |
| `fct_orders` | one order | `stg_tpch__orders` + rolled-up lines |
| `fct_order_lines` | one order line | `int_order_lines_enriched` (incremental) |
| `rpt_region_sales_vs_target` | one region per year | `fct_order_lines` + targets |
| `snap_region_targets` | SCD2 version of a target | `stg_raw__region_targets` |

Staging renames to snake_case and casts types only — no joins. All business
logic lives in intermediate, where `net_revenue = extended_price × (1 − discount)`
is defined once.

---

## 3. How to run

**Setup (once)**

1. `00_setup.sql` — warehouse `DBT_WH` (XSMALL, `AUTO_SUSPEND = 60`), resource
   monitor `TRIAL_RM` at a 20-credit quota, role `DBT_ROLE`, database `ANALYTICS`
   with four schemas, grants.
2. `01_load_raw.sql` — file format, internal stage, `REGION_TARGETS` table, `COPY INTO`.

**Development**

3. Open the project in a Snowsight Workspace.
4. Run `build --target dev` from the run control. (The control supplies the `dbt`
   prefix itself.)

**Deployment**

5. Workspace › Deployment › Deploy dbt project → `ANALYTICS.MARTS`.
6. Run it from a worksheet:

```sql
EXECUTE DBT PROJECT ANALYTICS.MARTS.SALES_ANALYTICS
  ARGS = 'build --target prod';
```

7. A daily Task runs the same command:

```sql
CREATE OR REPLACE TASK ANALYTICS.MARTS.T_RUN_SALES_ANALYTICS
  WAREHOUSE = DBT_WH
  SCHEDULE  = 'USING CRON 0 2 * * * Asia/Kolkata'
AS
  EXECUTE DBT PROJECT ANALYTICS.MARTS.SALES_ANALYTICS ARGS = 'build --target prod';
```

The task was resumed, run once successfully, then suspended to conserve credits.

---

## 4. Testing

| Type | Coverage |
| --- | --- |
| `unique`, `not_null` | every model key |
| `relationships` | facts → dims (`fct_order_lines` → `fct_orders`, `dim_customers`, `dim_parts`) |
| `accepted_values` | `order_status` in `('O', 'F', 'P')` |
| Singular | `assert_no_negative_net_revenue` |
| Singular | `assert_order_total_matches_lines` — order revenue equals the sum of its lines within a tolerance of 1 |
| Source freshness | `raw.region_targets` via `loaded_at` |

The tolerance in the second singular test is deliberate: line-level rounding to
two decimals means the aggregate will not reconcile to the cent.

---

## 5. Design choices

**`fct_order_lines` is incremental.** At 6M rows it is the only model where a full
rebuild dominates runtime and credits. Order date is append-only in TPC-H, so a
date watermark with `incremental_strategy = 'merge'` on the surrogate key lets each
scheduled run process only new dates. `fct_orders` stays a full table — 1.5M rows
rebuild cheaply, and the aggregate must stay consistent with its lines, which the
singular test verifies.

**Views for staging and intermediate, tables for marts.** Thin transformations
should never drift from their source and cost nothing to materialize as views.
Marts are queried repeatedly, so the compute is better spent once at build time.

**`dim_parts` and `dim_regions` read straight from staging.** Neither needs a join
or derived logic. A pass-through intermediate model would add a layer that
transforms nothing. `dim_customers` does go through `int_customers_with_region`,
because the nation → region walk is real logic worth defining once.

**Surrogate key on order lines.** `LINEITEM`'s natural key is composite
(`order_key` + `line_number`), so `order_line_key` as an MD5 of both gives the fact
table a single `unique` test and a clean merge key for the incremental strategy.

**Tasks run with narrower privileges than worksheets.** The first scheduled run
failed on `stg_raw__region_targets` with a permissions error on `ANALYTICS.RAW`,
while the same `EXECUTE DBT PROJECT` succeeded manually. A task executes with the
owner's primary role and no secondary roles active, so inherited access via
database ownership was not enough — `ANALYTICS.RAW` needed an explicit
`GRANT USAGE` to `DBT_ROLE`.

**Gross margin is an assumption.** TPC-H has no cost column, so cost is modelled as
60% of retail price. The margin figures are directionally useful, not real.

**The raw load is not idempotent.** Re-running `COPY INTO` against a regenerated
file duplicates rows (this happened once — 30 rows instead of 15). Fix is
`TRUNCATE` first, or a `MERGE` on `(region, target_year)`.

---

## 6. Findings

TPC-H is generated with a uniform distribution, so the five regions land within a
few percent of each other in every year — roughly 6.5–6.7 billion in net revenue
per region per year. There is no genuine regional signal in this data, and any
pattern in the variance report comes from the targets, which are invented. Saying
so is more honest than presenting a 0.3% gap as a business insight.

Average discount runs near 5% across all market segments, again by construction.

See `analysis/business_queries.sql` for the five queries and their findings.

---

## 7. Cost

Credits used: **[figure from `WAREHOUSE_METERING_HISTORY`]** against a 20-credit quota.

```sql
SELECT warehouse_name, ROUND(SUM(credits_used), 4) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
GROUP BY warehouse_name;
```

Kept low by: a single XSMALL warehouse with `AUTO_SUSPEND = 60`; dropping the
default `COMPUTE_WH`; a resource monitor that notifies at 80% and suspends at 100%;
selective `--select` builds during development rather than full rebuilds; and
suspending the scheduled task after one successful run.

---

## 8. Repository

00_setup.sql Warehouse, monitor, role, schemas, grants
01_load_raw.sql File format, stage, table, COPY INTO
data/region_targets.csv Hand-built targets, 15 rows
dbt_project.yml Per-folder schemas and materializations
profiles.yml dev and prod targets
models/staging/ _sources.yml, _staging.yml, 7 models
models/intermediate/ 2 models
models/marts/ _marts.yml, 6 models
snapshots/ snap_region_targets.sql
tests/ 2 singular tests
analysis/business_queries.sql 5 queries with findings
screenshots/ DAG, green build, task run, failed test, snapshot SCD2
