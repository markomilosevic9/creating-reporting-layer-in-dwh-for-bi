-- incremental mock data sample

-- 1st batch - 3 active subscriptions from the initial batch are now closed
-- updates propagate through staging to data mart on next pipeline execution

BEGIN;
UPDATE source.raw_subscriptions
SET end_date = '2025-01-15'
WHERE sub_id = 12
;
COMMIT;

BEGIN;
UPDATE source.raw_subscriptions
SET end_date = '2025-01-20'
WHERE sub_id = 13
;
COMMIT;

BEGIN;
UPDATE source.raw_subscriptions
SET end_date = '2025-02-01'
WHERE sub_id = 14
;
COMMIT;


-- 2nd batch - new customers added 
-- 3 clean records, 2 with predefined DQ issues
BEGIN;
INSERT INTO source.raw_customers (company_name, country, signup_date)
VALUES ('Company Sixteen', 'Country A', '2025-01-03'),
       ('Company Seventeen', 'Country A', '2025-01-08'),
       ('Company Eighteen', 'Country B', '2025-01-15'),
       -- predefined subset of data with DQ issues
       (NULL, 'Country C', '2025-01-10'), -- predefined DQ issue - NULL company_name
       ('Company Twenty', 'Country A', '1990-06-01')  -- predefined DQ issue - DATE_OUT_OF_RANGE signup_date is unreasonable
;
COMMIT;


-- 3rd batch - new subscriptions
BEGIN;
INSERT INTO source.raw_subscriptions (customer_id, plan_type, start_date, end_date, amount)
VALUES (3, 'Monthly', '2025-01-05', NULL, 48000),  -- overlap
       (16, 'Monthly', '2025-01-08', '2025-02-15', 90000),
       (17, 'Monthly', '2025-01-10', NULL, 53000),
       (18, 'Annual', '2025-01-15', NULL, 148000),
       -- predefined subset of data containing records with DQ issues
       (3, 'Quarterly', '2025-01-20', NULL, 72000), -- predefined DQ issue - INVALID_CATEGORY plan_type
       (16, 'Monthly', '2025-02-10', '2025-01-25', 91000), -- predefined DQ issue - DATE_LOGIC_ERROR start_date before end_date
       (17, 'Monthly', '2626-03-01', NULL, 53000), -- predefined DQ issue - DATE_OUT_OF_RANGE start_date
       (18, 'Annual', '2025-01-20', NULL, -8000)   -- predefined DQ issue - NEGATIVE_NUMBER amount
;
COMMIT;


-- 4th batch - new transactions
BEGIN;
INSERT INTO source.raw_transactions (sub_id, tx_date, status)
VALUES (12, '2025-01-10', 'Success'),
       (13, '2025-01-15', 'Success'),
       (14, '2025-01-20', 'Success'),
       (14, '2025-01-28', 'Success'),
       (22, '2025-01-25', 'Success'),
       -- predefined subset of data containing records with DQ issues
       (12, '2025-01-10', 'Success'),  -- predefined DQ issue - duplicate 
       (23, '2025-01-05', 'Success'),  -- predefined DQ issue - DATE_LOGIC_ERROR tx_date before start_date
       (24, '2025-01-20', 'Processing'),   -- predefined DQ issue - INVALID_CATEGORY status
       (8888, '2025-01-30', 'Success'),  -- predefined DQ issue - MISSING_FK, non-existent ID
       (22, '2035-01-15', 'Success')   -- predefined DQ issue - DATE_OUT_OF_RANGE tx_date
;
COMMIT;