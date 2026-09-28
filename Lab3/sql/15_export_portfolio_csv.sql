-- Lab3-15. 포트폴리오 증빙용 CSV 다운로드
-- Athena Console에서 문장을 하나씩 실행한 뒤 Query results의 Download results를 누른다.
-- 권장 파일명: lab3_raw_11000.csv, lab3_silver_5488.csv, lab3_gold_997.csv

-- 1) 입력 Raw 11,000건
SELECT
    order_id,
    customer_id,
    product_id,
    amount,
    order_date
FROM sales_db.sales2_dirty_raw
ORDER BY TRY_CAST(TRIM(order_id) AS BIGINT), order_id;

-- 2) 확정 Silver Snapshot 5,488건
-- Snapshot이 VACUUM으로 만료되지 않았을 때 실행할 수 있다.
SELECT
    order_id,
    customer_id,
    product_id,
    amount,
    order_timestamp,
    customer_total_amount
FROM commerce_lakehouse.silver_orders
FOR VERSION AS OF 8329354579635974189
ORDER BY order_id;

-- 3) 현재 Gold 고객 요약 997건
-- 14번 SQL로 확정 Silver 기준 재생성을 마친 뒤 다운로드한다.
SELECT
    customer_id,
    order_count,
    total_purchase_amount,
    average_order_amount,
    distinct_product_count,
    first_order_timestamp,
    last_order_timestamp
FROM commerce_lakehouse.gold_customer_summary
ORDER BY customer_id;
