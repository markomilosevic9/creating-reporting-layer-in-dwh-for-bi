-- queries made per requirements in part 2) of task description


-- query 1: mrr (monthly recurring revenue)

-- generates one row per calendar month per subscription using generate_series
-- monthly plans provides their full amount while they are active, but annual plans are divided by 12 and spread across months
-- COALESCE handles active subscriptions (meaning end_date IS NULL), since generate_series requires a non-NULL upper bound
-- MAX(COALESCE(end_date, start_date)) resolves to the date range provided in mock data samples to avoid calculations beyond it
-- in a real business use-case, CURRENT_DATE would be the natural choice to reflect "real-time" mrr
-- in this case, the cap is derived from mock data to avoid calculations for months with no mock data present e.g. in 2026

WITH subscription_months AS (SELECT s.sub_id,
                                    s.plan_type,
                                    s.amount,
                                    generate_series(DATE_TRUNC('month', s.start_date),
                                                    DATE_TRUNC('month', COALESCE(s.end_date, (SELECT MAX(COALESCE(end_date, start_date))
                                                                                              FROM dwh.stg_subscriptions))),
                                    INTERVAL '1 month') AS revenue_month
                             FROM dwh.stg_subscriptions AS s)
SELECT TO_CHAR(revenue_month, 'YYYY-MM') AS reporting_month,
       ROUND(SUM(CASE
                   WHEN plan_type = 'Monthly' THEN amount
                   WHEN plan_type = 'Annual'  THEN amount / 12.0
                 END), 2) AS mrr
FROM subscription_months
GROUP BY revenue_month
ORDER BY revenue_month
;


-- query 2: cumulative ltv per customer

-- spending per transaction is get from the linked subscriptions
-- multiple successful transactions within the same month are summed and this reflects customer's actual spending
-- month series are generated from signup_date - per task requirement - to the customer's last transaction month
-- months with no successful transactions show monthly_spend = 0 and cumulative_ltv just carries forward
WITH successful_transactions AS (SELECT t.tx_id,
                                        s.customer_id,
                                        DATE_TRUNC('month', t.tx_date) AS spend_month,
                                        s.amount AS tx_spend
                                FROM dwh.stg_transactions AS t
                                INNER JOIN dwh.stg_subscriptions AS s
                                ON s.sub_id = t.sub_id
                                WHERE t.status = 'Success'),
monthly_spend AS (SELECT customer_id,
                         spend_month,
                         ROUND(SUM(tx_spend), 2) AS month_total
                 FROM successful_transactions
                 GROUP BY customer_id,
                          spend_month),
customer_last_month AS (SELECT customer_id,
                               MAX(spend_month) AS last_month
                        FROM monthly_spend
                        GROUP BY customer_id),
customer_months AS (SELECT c.customer_id,
                           generate_series(DATE_TRUNC('month', c.signup_date),
                           clm.last_month,
                           INTERVAL '1 month') AS month
                    FROM dwh.stg_customers AS c
                    INNER JOIN customer_last_month AS clm
                    ON clm.customer_id = c.customer_id)
SELECT c.company_name,
       TO_CHAR(cm.month, 'YYYY-MM') AS spend_month,
       COALESCE(ms.month_total, 0) AS monthly_spend,
       ROUND(SUM(COALESCE(ms.month_total, 0)) OVER (PARTITION BY cm.customer_id
                                                      ORDER BY cm.month), 2) AS cumulative_ltv
FROM customer_months AS cm
INNER JOIN dwh.stg_customers AS c
ON c.customer_id = cm.customer_id
LEFT JOIN monthly_spend AS ms
ON ms.customer_id = cm.customer_id
AND ms.spend_month = cm.month
ORDER BY c.company_name,
         cm.month
;