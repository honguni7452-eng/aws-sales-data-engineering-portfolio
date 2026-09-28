-- Lab3-09. Silver 전체 재적재
-- 이미 적재된 행을 비운 뒤 최종 조건으로 다시 적재한다.
-- 재현성을 위해 실행 시점의 CURRENT_TIMESTAMP/current_date를 사용하지 않고
-- 최종 Silver Snapshot을 생성한 기준일인 2026-08-18을 고정한다.

DELETE FROM commerce_lakehouse.silver_orders;

INSERT INTO commerce_lakehouse.silver_orders
    (
        order_id,
        customer_id,
        product_id,
        amount,
        order_timestamp,
        customer_total_amount
    )
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
),
deduplicated AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        amount,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_id
        ) AS row_num
    FROM typed_data
),
filtered AS (
    SELECT
        d.order_id,
        d.customer_id,
        d.product_id,
        d.amount,
        d.order_date
    FROM deduplicated d
    CROSS JOIN parameters p
    WHERE d.row_num = 1
      AND d.amount > 0
      AND d.order_date BETWEEN p.reference_date - INTERVAL '90' DAY
                           AND p.reference_date
)
SELECT
    order_id,
    customer_id,
    product_id,
    amount,
    CAST(order_date AS TIMESTAMP) AS order_timestamp,
    CAST(
        SUM(amount) OVER (PARTITION BY customer_id)
        AS DECIMAL(20, 2)
    ) AS customer_total_amount
FROM filtered;

SELECT *
FROM commerce_lakehouse.silver_orders
ORDER BY order_timestamp DESC, order_id
LIMIT 100;
