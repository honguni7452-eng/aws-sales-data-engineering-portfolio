-- Lab3-10. Silver 최종 검증
-- duplicate, non_positive, outside_90_days는 모두 0이어야 한다.
-- 기준일은 최종 Snapshot 생성일인 2026-08-18로 고정한다.

WITH parameters AS (
    SELECT DATE '2026-08-18' AS reference_date
)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows,
    SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS non_positive_amount_rows,
    SUM(
        CASE WHEN CAST(order_timestamp AS DATE) < reference_date - INTERVAL '90' DAY
                   OR CAST(order_timestamp AS DATE) > reference_date
             THEN 1 ELSE 0 END
    ) AS outside_recent_90_days_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_rows
FROM commerce_lakehouse.silver_orders
CROSS JOIN parameters
GROUP BY reference_date;

-- 최종 확인 결과: total_rows 5,488 / distinct_orders 5,488 / duplicate_rows 0

-- 중복이 남았는지 상세 확인: 결과가 0행이어야 한다.
SELECT order_id, COUNT(*) AS row_count
FROM commerce_lakehouse.silver_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 정제된 날짜 범위 확인
SELECT
    MIN(order_timestamp) AS min_order_timestamp,
    MAX(order_timestamp) AS max_order_timestamp
FROM commerce_lakehouse.silver_orders;

-- Iceberg Hidden Partition 확인
SELECT *
FROM "commerce_lakehouse"."silver_orders$partitions";
