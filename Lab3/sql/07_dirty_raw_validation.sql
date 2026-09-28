-- Lab3-07. Silver 적재 전 Dirty Raw 데이터 검사

WITH parameters AS (
    SELECT DATE '2026-08-18' AS reference_date
),
typed_data AS (
    SELECT
        TRY_CAST(TRIM(order_id) AS BIGINT) AS order_id,
        TRY_CAST(NULLIF(TRIM(customer_id), '') AS BIGINT) AS customer_id,
        TRY_CAST(TRIM(product_id) AS BIGINT) AS product_id,
        TRY_CAST(TRIM(amount) AS DECIMAL(10, 2)) AS amount,
        TRY_CAST(TRIM(order_date) AS DATE) AS order_date
    FROM sales_db.sales2_dirty_raw
)
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_rows,
    SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS non_positive_amount_rows,
    SUM(CASE WHEN order_date < reference_date - INTERVAL '90' DAY
               OR order_date > reference_date
             THEN 1 ELSE 0 END) AS outside_recent_90_days_rows
FROM typed_data
CROSS JOIN parameters
GROUP BY reference_date;

-- 타입 변환에 실패한 값 확인
WITH typed_data AS (
    SELECT
        order_id AS raw_order_id,
        customer_id AS raw_customer_id,
        product_id AS raw_product_id,
        amount AS raw_amount,
        order_date AS raw_order_date,
        TRY_CAST(TRIM(order_id) AS BIGINT) AS typed_order_id,
        TRY_CAST(NULLIF(TRIM(customer_id), '') AS BIGINT) AS typed_customer_id,
        TRY_CAST(TRIM(product_id) AS BIGINT) AS typed_product_id,
        TRY_CAST(TRIM(amount) AS DECIMAL(10, 2)) AS typed_amount,
        TRY_CAST(TRIM(order_date) AS DATE) AS typed_order_date
    FROM sales_db.sales2_dirty_raw
)
SELECT *
FROM typed_data
WHERE typed_order_id IS NULL
   OR typed_product_id IS NULL
   OR typed_amount IS NULL
   OR typed_order_date IS NULL
LIMIT 100;
