-- Run each statement separately in Athena after commerce-silver-transform succeeds.
-- This table is produced by Lab4 Glue, not the existing Lab3 Silver table.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(order_id) - COUNT(DISTINCT order_id) AS duplicate_excess_rows,
    COUNT_IF(order_id IS NULL OR customer_id IS NULL OR product_id IS NULL) AS null_key_rows,
    COUNT_IF(amount IS NULL OR amount <= 0) AS invalid_amount_rows,
    COUNT_IF(order_timestamp IS NULL OR order_date IS NULL) AS null_date_rows,
    COUNT_IF(order_date > DATE '2026-09-08') AS future_rows,
    COUNT_IF(order_date <> CAST(order_timestamp AS DATE)) AS date_mismatch_rows,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(amount) AS total_amount,
    MIN(order_date) AS first_date,
    MAX(order_date) AS last_date
FROM commerce_lakehouse_lab4.silver_orders;

-- Compare every output column in both directions against an independent SQL transform.
-- Replace <BRONZE_SNAPSHOT_ID> with the snapshot selected during preflight.
WITH expected AS (
    SELECT DISTINCT order_id, customer_id, product_id, amount,
           order_timestamp, CAST(order_timestamp AS DATE) AS order_date
    FROM commerce_lakehouse.bronze_orders FOR VERSION AS OF <BRONZE_SNAPSHOT_ID>
    WHERE order_id IS NOT NULL AND customer_id IS NOT NULL
      AND product_id IS NOT NULL AND amount > 0
      AND order_timestamp IS NOT NULL
      AND CAST(order_timestamp AS DATE) <= DATE '2026-09-08'
), missing AS (
    SELECT * FROM expected
    EXCEPT
    SELECT order_id, customer_id, product_id, amount, order_timestamp, order_date
    FROM commerce_lakehouse_lab4.silver_orders
), unexpected AS (
    SELECT order_id, customer_id, product_id, amount, order_timestamp, order_date
    FROM commerce_lakehouse_lab4.silver_orders
    EXCEPT
    SELECT * FROM expected
)
SELECT 'missing_in_silver' AS check_name, COUNT(*) AS difference_rows FROM missing
UNION ALL
SELECT 'unexpected_in_silver', COUNT(*) FROM unexpected;

SELECT order_id, customer_id, product_id, amount, order_timestamp, order_date
FROM commerce_lakehouse_lab4.silver_orders
ORDER BY order_timestamp DESC, order_id
LIMIT 10;

SHOW CREATE TABLE commerce_lakehouse_lab4.silver_orders;

SELECT * FROM "commerce_lakehouse_lab4"."silver_orders$partitions";
