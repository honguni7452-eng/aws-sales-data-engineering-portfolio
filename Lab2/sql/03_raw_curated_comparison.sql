-- Lab2-03. Raw CSV와 Curated Parquet 지표 비교

-- 1) 행 수 비교
SELECT
    'sales2_dirty_raw' AS table_name,
    COUNT(*) AS row_count
FROM sales_db.sales2_dirty_raw

UNION ALL

SELECT
    'sales2_curated' AS table_name,
    COUNT(*) AS row_count
FROM sales_db.sales2;

-- 2) 핵심 지표 비교
-- Raw는 정제 조건을 SQL에서 적용하여 Curated와 같은 기준으로 맞춘다.
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
metrics AS (
    SELECT
        'cleaned_raw' AS table_name,
        COUNT(*) AS row_count,
        COUNT(DISTINCT customer_id) AS customer_count,
        COUNT(DISTINCT product_id) AS product_count,
        ROUND(SUM(amount), 2) AS total_sales,
        ROUND(AVG(amount), 2) AS average_amount
    FROM clean_raw

    UNION ALL

    SELECT
        'sales2_curated' AS table_name,
        COUNT(*) AS row_count,
        COUNT(DISTINCT customer_id) AS customer_count,
        COUNT(DISTINCT product_id) AS product_count,
        ROUND(SUM(amount), 2) AS total_sales,
        ROUND(AVG(amount), 2) AS average_amount
    FROM sales_db.sales2
)
SELECT *
FROM metrics;
