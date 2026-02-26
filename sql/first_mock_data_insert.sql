-- initial mock data sample


-- mock data insertion into source.raw_customers
-- 15 records
-- 2 DQ issues: NULL country, NULL company_name
BEGIN;
INSERT INTO source.raw_customers (company_name, country, signup_date)
VALUES ('Company One', 'Country A', '2023-12-15'),
       ('Company Two', 'Country B', '2024-01-05'),
       ('Company Three', 'Country C', '2024-01-10'),
       ('Company Four', 'Country A', '2024-01-20'),
       ('Company Five', 'Country A', '2024-02-01'),
       ('Company Six', 'Country C', '2024-02-10'),
       ('Company Seven', 'Country B', '2024-03-05'),
       ('Company Eight', 'Country A', '2024-04-10'),
       ('Company Nine', 'Country C', '2024-05-01'),
       ('Company Ten', 'Country A', '2024-06-15'),
       ('Company Eleven', 'Country A', '2024-07-20'),
       ('Company Twelve', 'Country B', '2024-08-10'),
       -- predefined subset of data with DQ issues
       ('Company Thirteen', NULL, '2024-09-01'), -- predefined DQ issue - NULL country
       (NULL, 'Country C', '2024-09-15'), -- predefined DQ issue - NULL company_name
       ('Company Fifteen', 'Country A', '2024-10-01')
;
COMMIT;


-- mock data insertion into source.raw_subscriptions
-- 20 records
-- 5 DQ issues: invalid category, problematic DATEs, NULL values, missing FK
BEGIN;
INSERT INTO source.raw_subscriptions (customer_id, plan_type, start_date, end_date, amount)
VALUES (1, 'Monthly', '2024-01-15', '2024-02-28', 95000),
       (2, 'Monthly', '2024-01-20', '2024-03-05', 55000),
       (3, 'Annual', '2024-02-01', '2024-04-10', 150000),
       (5, 'Monthly', '2024-02-15', '2024-03-20', 52000),
       (7, 'Monthly', '2024-04-01', '2024-05-15', 88000),
       (9, 'Annual', '2024-06-10', '2024-08-05', 145000),
       (11, 'Monthly', '2024-08-20', '2024-10-01', 93000),
       (4, 'Monthly', '2024-02-10', '2024-03-10', 87000),
       (6, 'Monthly', '2024-03-15', '2024-04-20', 53000),
       (8, 'Annual', '2024-05-05', '2024-06-15', 140000),
       (10, 'Monthly', '2024-07-10', '2024-08-15', 51000),
       (12, 'Monthly', '2024-09-01', NULL, 94000),
       (15, 'Monthly', '2024-10-10', NULL, 57000),
       (1, 'Annual', '2024-11-10', NULL, 160000), 
       (2, 'Monthly', '2024-11-01', NULL, 87000), 
       -- predefined subset of data containing problematic records with DQ issues
       (4, 'Quarterly', '2024-02-10', '2024-03-15', 78000), -- predefined DQ issue - INVALID_CATEGORY plan_type
       (6, 'Monthly', '2024-04-01', '2024-03-15', 82000), -- predefined DQ issue - DATE_LOGIC_ERROR start_date before end_date
       (9999, 'Monthly', '2024-03-20', '2024-04-25', 55000), -- predefined DQ issue - MISSING_FK, non-existent ID 
       (8, NULL, '2024-06-01', '2024-07-10', 60000), -- predefined DQ issue - NULL_VALUE plan_type
       (10, 'Monthly', NULL, '2024-08-20', 52000)  -- predefined DQ issue - NULL_VALUE start_date
;
COMMIT;


-- mock data insertion into source.raw_transactions
-- 19 records
-- 5 DQ issues: duplicate, problematic DATE, invalid category, NULL value, missing FK
BEGIN;
INSERT INTO source.raw_transactions (sub_id, tx_date, status)
VALUES (1, '2024-01-25', 'Success'),
       (1, '2024-02-15', 'Success'),
       (2, '2024-02-05', 'Success'),
       (3, '2024-02-15', 'Success'),
       (3, '2024-03-20', 'Success'),
       (4, '2024-02-25', 'Success'),
       (5, '2024-04-15', 'Success'),
       (6, '2024-06-25', 'Success'),
       (6, '2024-07-20', 'Success'),
       (7, '2024-09-10', 'Success'),
       -- predefined subset of data containing failed/refunded transactions
       (8, '2024-02-20', 'Failed'),
       (9, '2024-03-28', 'Refunded'),
       (10, '2024-05-20', 'Failed'),
       (11, '2024-07-25', 'Failed'),
       -- predefined subset of data containing records with DQ issues
       (1, '2024-01-25', 'Success'),  -- predefined DQ issue - DUPLICATE 
       (2, '2024-01-15', 'Success'),  -- predefined DQ issue - DATE_LOGIC_ERROR tx_date before start_date
       (5, '2024-04-10', 'Processing'), -- predefined DQ issue - INVALID_CATEGORY status
       (NULL, '2024-07-01', 'Success'),  -- predefined DQ issue - NULL_VALUE, no sub_id
       (9999, '2024-08-15', 'Success')   -- predefined DQ issue - MISSING_FK, non-existent ID
;
COMMIT;