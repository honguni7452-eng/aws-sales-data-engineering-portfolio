-- Lab2-04. 정제한 Raw와 Curated가 실제로 같은지 양방향 검사
-- 두 결과가 모두 0행이면 데이터가 일치한다.

WITH typed_raw AS (
    SELECT
        TRY_CAST(TRIM(order_id) AS BIGINT) AS order_id,
        TRY_CAST(NULLIF(TRIM(customer_id), '') AS BIGINT) AS customer_id,
        TRY_CAST(TRIM(product_id) AS BIGINT) AS product_id,
        TRY_CAST(TRIM(amount) AS DECIMAL(10, 2)) AS amount,
        TRY_CAST(TRIM(order_date) AS DATE) AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY TRY_CAST(TRIM(order_id) AS BIGINT)
            ORDER BY TRY_CAST(TRIM(order_id) AS BIGINT)
        ) AS row_num
    FROM sales_db.sales2_dirty_raw
),
clean_raw AS (
    SELECT order_id, customer_id, product_id, amount, order_date
    FROM typed_raw
    WHERE row_num = 1
      AND order_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND product_id IS NOT NULL
      AND amount > 0
      AND order_date IS NOT NULL
      AND order_date <= current_date
),
raw_only AS (
    SELECT * FROM clean_raw
    EXCEPT
    SELECT order_id, customer_id, product_id, amount, TRY_CAST(order_date AS DATE) AS order_date
    FROM sales_db.sales2
),
curated_only AS (
    SELECT order_id, customer_id, product_id, amount, TRY_CAST(order_date AS DATE) AS order_date
    FROM sales_db.sales2
    EXCEPT
    SELECT * FROM clean_raw
)
SELECT 'raw_only' AS difference_type, COUNT(*) AS difference_count
FROM raw_only

UNION ALL

SELECT 'curated_only' AS difference_type, COUNT(*) AS difference_count
FROM curated_only;
