-- Lab3-14. Silver Snapshot 복원 및 Gold 최종 재생성
-- 최종 기준: 2026-08-18 생성 Snapshot 8329354579635974189
-- Athena Console에서는 아래 문장을 세미콜론 단위로 하나씩 실행한다.
-- VACUUM으로 Snapshot을 만료시키기 전에 실행해야 한다.

-- 1) Silver Snapshot 목록 확인
SELECT
    committed_at,
    snapshot_id,
    parent_id,
    operation,
    summary
FROM "commerce_lakehouse"."silver_orders$snapshots"
ORDER BY committed_at DESC;

-- 2) 5,488건 Silver Snapshot 확인
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM commerce_lakehouse.silver_orders
FOR VERSION AS OF 8329354579635974189;

-- 확인 결과: total_rows 5,488 / distinct_orders 5,488

-- 3) 현재 Silver 데이터 삭제
DELETE FROM commerce_lakehouse.silver_orders;

-- 4) 5,488건 과거 Snapshot을 현재 Silver로 복원
INSERT INTO commerce_lakehouse.silver_orders
    (
        order_id,
        customer_id,
        product_id,
        amount,
        order_timestamp,
        customer_total_amount
    )
SELECT
    order_id,
    customer_id,
    product_id,
    amount,
    order_timestamp,
    customer_total_amount
FROM commerce_lakehouse.silver_orders
FOR VERSION AS OF 8329354579635974189;

-- 5) 복원된 Silver 검증
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM commerce_lakehouse.silver_orders;

-- 정상 결과: total_rows 5,488 / distinct_orders 5,488 / duplicate_rows 0

-- 6) 기존 Gold 고객 요약 데이터 삭제
DELETE FROM commerce_lakehouse.gold_customer_summary;

-- 7) 5,488건 Silver 기준으로 Gold 고객 요약 재적재
INSERT INTO commerce_lakehouse.gold_customer_summary
    (
        customer_id,
        order_count,
        total_purchase_amount,
        average_order_amount,
        distinct_product_count,
        first_order_timestamp,
        last_order_timestamp
    )
SELECT
    customer_id,
    COUNT(*) AS order_count,
    MAX(customer_total_amount) AS total_purchase_amount,
    CAST(AVG(amount) AS DECIMAL(20, 2)) AS average_order_amount,
    COUNT(DISTINCT product_id) AS distinct_product_count,
    MIN(order_timestamp) AS first_order_timestamp,
    MAX(order_timestamp) AS last_order_timestamp
FROM commerce_lakehouse.silver_orders
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

-- 8) Gold 고객 수와 중복 검증
SELECT
    COUNT(*) AS gold_customers,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customers
FROM commerce_lakehouse.gold_customer_summary;

-- 정상 결과: gold_customers 997 / distinct_customers 997 / duplicate_customers 0

-- 9) 누락 고객·예상하지 않은 고객·고객 집계 오류 검증
WITH silver_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        MAX(customer_total_amount) AS total_purchase_amount,
        CAST(AVG(amount) AS DECIMAL(20, 2)) AS average_order_amount,
        COUNT(DISTINCT product_id) AS distinct_product_count,
        MIN(order_timestamp) AS first_order_timestamp,
        MAX(order_timestamp) AS last_order_timestamp
    FROM commerce_lakehouse.silver_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
comparison AS (
    SELECT
        s.customer_id AS silver_customer_id,
        g.customer_id AS gold_customer_id,
        CASE
            WHEN s.customer_id IS NOT NULL
             AND g.customer_id IS NOT NULL
             AND (
                    s.order_count IS DISTINCT FROM g.order_count
                 OR s.total_purchase_amount IS DISTINCT FROM g.total_purchase_amount
                 OR s.average_order_amount IS DISTINCT FROM g.average_order_amount
                 OR s.distinct_product_count IS DISTINCT FROM g.distinct_product_count
                 OR s.first_order_timestamp IS DISTINCT FROM g.first_order_timestamp
                 OR s.last_order_timestamp IS DISTINCT FROM g.last_order_timestamp
             )
            THEN 1 ELSE 0
        END AS aggregation_error
    FROM silver_summary s
    FULL OUTER JOIN commerce_lakehouse.gold_customer_summary g
        ON s.customer_id = g.customer_id
)
SELECT
    SUM(CASE WHEN silver_customer_id IS NOT NULL
                   AND gold_customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customers,
    SUM(CASE WHEN silver_customer_id IS NULL
                   AND gold_customer_id IS NOT NULL THEN 1 ELSE 0 END) AS unexpected_customers,
    SUM(aggregation_error) AS aggregation_errors
FROM comparison;

-- 정상 결과: missing_customers 0 / unexpected_customers 0 / aggregation_errors 0
