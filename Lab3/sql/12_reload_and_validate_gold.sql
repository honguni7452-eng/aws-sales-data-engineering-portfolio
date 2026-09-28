-- Lab3-12. Gold 고객 요약 재적재 및 검증
-- 기준 데이터: Silver Snapshot 8329354579635974189에서 복원한 5,488개 주문

DELETE FROM commerce_lakehouse.gold_customer_summary;

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

-- 구매금액 상위 고객
SELECT *
FROM commerce_lakehouse.gold_customer_summary
ORDER BY total_purchase_amount DESC, customer_id
LIMIT 100;

-- Gold 고객 수와 중복 고객 검증
SELECT
    COUNT(*) AS gold_customers,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customers
FROM commerce_lakehouse.gold_customer_summary;

-- 최종 확인 결과: gold_customers 997 / duplicate_customers 0

-- Silver 고객을 기준으로 Gold 누락·예상 외 고객·집계 오류를 한 번에 검증한다.
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

-- 최종 확인 결과: missing_customers 0 / unexpected_customers 0 / aggregation_errors 0
