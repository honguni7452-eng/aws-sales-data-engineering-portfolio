-- Lab2-01. Dirty Raw 데이터 품질 검사
-- Raw 테이블의 모든 컬럼이 문자열로 추론되더라도 검사할 수 있도록 TRY_CAST를 사용한다.

WITH typed_data AS (
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
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_rows,
    SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS non_positive_amount_rows,
    SUM(CASE WHEN order_date > current_date THEN 1 ELSE 0 END) AS future_date_rows
FROM typed_data;

-- 중복 order_id 상세 확인
WITH typed_data AS (
    SELECT TRY_CAST(TRIM(order_id) AS BIGINT) AS order_id
    FROM sales_db.sales2_dirty_raw
)
SELECT order_id, COUNT(*) AS duplicate_count
FROM typed_data
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, order_id;

-- NULL 고객 샘플
SELECT *
FROM sales_db.sales2_dirty_raw
WHERE TRY_CAST(NULLIF(TRIM(customer_id), '') AS BIGINT) IS NULL
LIMIT 20;

-- 음수 또는 0원 주문 샘플
SELECT *
FROM sales_db.sales2_dirty_raw
WHERE TRY_CAST(TRIM(amount) AS DECIMAL(10, 2)) <= 0
LIMIT 20;

-- 미래 날짜 주문 샘플
SELECT *
FROM sales_db.sales2_dirty_raw
WHERE TRY_CAST(TRIM(order_date) AS DATE) > current_date
LIMIT 20;
