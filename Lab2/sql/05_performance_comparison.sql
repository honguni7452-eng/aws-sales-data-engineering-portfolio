-- Lab2-05. CSV와 Parquet/Partition 성능 비교
-- 각 쿼리를 따로 실행하고 Athena의 Run time과 Data scanned를 기록한다.
-- 2026-08-25 실측 기준: 동일 일 매출 30,218.81, 쿼리 결과 재사용 비활성화.

-- 1) Raw CSV: Glue ETL과 동일한 타입 변환·품질 조건·중복 제거 후 집계
-- 실측: Run time 537 ms, Data scanned 327.09 KB
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
      AND order_date = DATE '2026-07-01'
)
SELECT
    order_date,
    ROUND(SUM(amount), 2) AS daily_sales
FROM clean_raw
GROUP BY order_date;

-- 2) Curated Parquet + order_date Partition: 해당 날짜 Partition과 필요한 컬럼만 읽음
-- 실제 Crawler 테이블의 Partition 컬럼은 string이다.
-- 실측: Run time 515 ms, Data scanned 0.57 KB
SELECT
    CAST(order_date AS DATE) AS order_date,
    ROUND(SUM(amount), 2) AS daily_sales
FROM sales_db.sales2
WHERE order_date = '2026-07-01'
GROUP BY order_date;

-- 3) 여러 날짜 범위 비교
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
      AND order_date BETWEEN DATE '2026-07-01' AND DATE '2026-07-07'
)
SELECT ROUND(SUM(amount), 2) AS total_sales
FROM clean_raw;

SELECT ROUND(SUM(amount), 2) AS total_sales
FROM sales_db.sales2
WHERE order_date BETWEEN '2026-07-01' AND '2026-07-07';
