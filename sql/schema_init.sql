-- the script contains DDL SQL code for initialization of schemas and tables according to the task description


-- source schema for raw data coming from CRM
-- stores data in "as-is" format
-- allows storing NULL values, duplicates and other data quality issues
CREATE SCHEMA IF NOT EXISTS source;

-- raw_ tables within source schema:

-- 1)
-- DDL for table source.raw_customers
-- natural/composite key for later deduplication - company_name + country + signup_date
CREATE TABLE IF NOT EXISTS source.raw_customers (customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK
                                                 company_name VARCHAR(100),
                                                 country VARCHAR(100),
                                                 signup_date DATE
);

-- 2)
-- DDL for table source.raw_subscriptions
-- natural/composite key for later deduplication - customer_id + plan_type + start_date
CREATE TABLE IF NOT EXISTS source.raw_subscriptions (sub_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK
                                                     customer_id BIGINT,
                                                     plan_type VARCHAR(100),
                                                     start_date DATE,
                                                     end_date DATE,
                                                     amount NUMERIC(12,2)
);

-- 3)
-- DDL for table source.raw_transactions
-- natural/composite key for later deduplication - sub_id + tx_date + status
CREATE TABLE IF NOT EXISTS source.raw_transactions (tx_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK
                                                    sub_id BIGINT,
                                                    tx_date DATE,
                                                    status VARCHAR(100)
);


-- dwh/datawarehouse schema
CREATE SCHEMA IF NOT EXISTS dwh;

-- helper tables within dwh schema:

-- 1)
-- DDL for table dwh.etl_runs
-- stores 1 row per pipeline execution
-- stores run_id used across dq_log to correlate all DQ issues that appear within a particular pipeline run
-- ended_at remains NULL if the pipeline fails before reaching the final completion step
-- status tracks pipeline state - RUNNING while in progress, COMPLETED on pipeline success
CREATE TABLE IF NOT EXISTS dwh.etl_runs (run_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK
                                         started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                         ended_at TIMESTAMP,
                                         status VARCHAR(20) NOT NULL DEFAULT 'RUNNING'
);


-- 2)
-- DDL for table dwh.dq_log
-- log of DQ issues found during pipeline runs
-- each unique issue is logged once when it is first detected and then updated on subsequent runs - please see the documentation for further explanation
-- run_id records which pipeline run first detected the issue; detected_at is the corresponding timestamp
-- last_seen_run_id tracks which pipeline run most recently re-detected the issue
-- this should provide persistent issue observability
-- during the pipeline executions, table is updated on every run via ON CONFLICT DO UPDATE, so it always reflects the latest state
-- detail provides context about the issue (e.g. which column was NULL)
-- generally, it covers the following 8 predefined/possible DQ issues (please see the documentation for more details)
CREATE TABLE IF NOT EXISTS dwh.dq_log (log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK
                                       run_id BIGINT NOT NULL REFERENCES dwh.etl_runs(run_id), -- FK 
                                       last_seen_run_id BIGINT NOT NULL, 
                                       table_name VARCHAR(100) NOT NULL,
                                       record_id BIGINT NOT NULL,
                                       issue_type VARCHAR(50) NOT NULL CHECK (issue_type IN ('NULL_VALUE',
                                                                                             'INVALID_CATEGORY',
                                                                                             'DATE_LOGIC_ERROR_DATES',
                                                                                             'DATE_LOGIC_ERROR_SIGNUP',
                                                                                             'DATE_OUT_OF_RANGE',
                                                                                             'NEGATIVE_NUMBER',
                                                                                             'DUPLICATE',
                                                                                             'MISSING_FK')),
                                       detail VARCHAR(300),
                                       detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                       CONSTRAINT unique_dq_log_record_issue UNIQUE (table_name, record_id, issue_type)
);


-- staging tables within dwh schema:

-- 1)
-- DDL for table dwh.stg_customers
CREATE TABLE IF NOT EXISTS dwh.stg_customers (customer_id BIGINT PRIMARY KEY, -- PK
                                              company_name VARCHAR(100) NOT NULL,
                                              country VARCHAR(100) NOT NULL,
                                              signup_date DATE NOT NULL,
                                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                              updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 2)
-- DDL for table dwh.stg_subscriptions
-- plan_type allows the 2 categoriess - Monthly/Annual
-- end_date is nullable - NULL means the subscription is still active
-- CHECK constraint ensures end_date, when present, is not earlier than start_date
CREATE TABLE IF NOT EXISTS dwh.stg_subscriptions (sub_id BIGINT PRIMARY KEY, -- PK
                                                  customer_id BIGINT NOT NULL REFERENCES dwh.stg_customers(customer_id), -- FK
                                                  plan_type VARCHAR(100) NOT NULL CHECK (plan_type IN ('Monthly', 'Annual')),
                                                  start_date DATE NOT NULL,
                                                  end_date DATE,
                                                  amount NUMERIC(12,2),
                                                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  CONSTRAINT check_end_date_after_start_date CHECK (end_date IS NULL OR end_date >= start_date) 
);


-- 3)
-- DDL for table dwh.stg_transactions
-- status allows the 3 categoriess - Success/Failed/Refunded
CREATE TABLE IF NOT EXISTS dwh.stg_transactions (tx_id BIGINT PRIMARY KEY, -- PK
                                                 sub_id BIGINT NOT NULL REFERENCES dwh.stg_subscriptions(sub_id), -- FK
                                                 tx_date DATE NOT NULL,
                                                 status VARCHAR(100) NOT NULL CHECK (status IN ('Success', 'Failed', 'Refunded')),
                                                 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- data mart table within dwh schema

-- DDL for table dwh.dm_sales_performance
CREATE TABLE IF NOT EXISTS dwh.dm_sales_performance (sub_id BIGINT PRIMARY KEY, -- PK 
                                                     company_name VARCHAR(100) NOT NULL,
                                                     country VARCHAR(100) NOT NULL,
                                                     subscription_duration INT,
                                                     total_successful_payments INT NOT NULL DEFAULT 0,
                                                     sum_successful_payments NUMERIC(12,2) NOT NULL DEFAULT 0,
                                                     updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);