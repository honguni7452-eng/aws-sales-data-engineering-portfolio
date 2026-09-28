-- 기존 Lab3 Silver 확인용. Lab4 Glue 실행 결과 검증과 구분한다.
-- Athena에서 두 SELECT를 각각 실행한다. 데이터 변경 없음.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(order_id) - COUNT(DISTINCT order_id) AS duplicate_excess_rows,
    COUNT_IF(order_id IS NULL) AS null_orders,
    COUNT_IF(customer_id IS NULL) AS null_customers,
    COUNT_IF(product_id IS NULL) AS null_products,
    COUNT_IF(amount IS NULL OR amount <= 0) AS invalid_amounts,
    COUNT_IF(order_timestamp IS NULL) AS null_timestamps,
    COUNT_IF(CAST(order_timestamp AS DATE) NOT BETWEEN
        DATE '2026-08-18' - INTERVAL '90' DAY AND DATE '2026-08-18') AS outside_lab3_date_window,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    MIN(order_timestamp) AS first_timestamp,
    MAX(order_timestamp) AS last_timestamp,
    SUM(amount) AS total_amount
FROM commerce_lakehouse.silver_orders;

SELECT order_id, customer_id, product_id, amount,
       order_timestamp, customer_total_amount
FROM commerce_lakehouse.silver_orders
ORDER BY order_timestamp DESC, order_id
LIMIT 10;
