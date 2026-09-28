-- Lab4 사전 점검. Athena에서 각 SELECT 문을 따로 실행한다.
-- 원본 테이블은 변경하지 않는다. 조회 및 결과 저장 비용이 발생할 수 있다.
SELECT 'dirty_raw' AS table_name, COUNT(*) AS row_count FROM sales_db.sales2_dirty_raw
UNION ALL
SELECT 'bronze_orders', COUNT(*) FROM commerce_lakehouse.bronze_orders
UNION ALL
SELECT 'silver_orders', COUNT(*) FROM commerce_lakehouse.silver_orders
UNION ALL
SELECT 'gold_customer_summary', COUNT(*) FROM commerce_lakehouse.gold_customer_summary
UNION ALL
SELECT 'gold_daily_sales', COUNT(*) FROM commerce_lakehouse.gold_daily_sales;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT_IF(order_id IS NULL) AS null_order_ids,
    COUNT_IF(customer_id IS NULL) AS null_customers,
    COUNT_IF(product_id IS NULL) AS null_products,
    COUNT_IF(amount IS NULL OR amount <= 0) AS invalid_amounts,
    COUNT_IF(order_timestamp IS NULL) AS null_timestamps,
    COUNT_IF(CAST(order_timestamp AS DATE) > DATE '2026-09-08') AS future_rows,
    MIN(order_timestamp) AS first_timestamp,
    MAX(order_timestamp) AS last_timestamp
FROM commerce_lakehouse.bronze_orders;
