-- Lab2-02. Curated 테이블 정제 결과 검증

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_rows,
    SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS non_positive_amount_rows,
    SUM(CASE WHEN TRY_CAST(order_date AS DATE) > current_date THEN 1 ELSE 0 END) AS future_date_rows
FROM sales_db.sales2;

-- 정상 데이터 10,000행으로 복원됐는지 확인
SELECT COUNT(*) AS expected_10000_rows
FROM sales_db.sales2;

-- 컬럼 타입과 Partition 컬럼 확인
DESCRIBE sales_db.sales2;

-- 날짜별 행 수: S3의 order_date Partition과 대응
SELECT
    order_date,
    COUNT(*) AS row_count
FROM sales_db.sales2
GROUP BY order_date
ORDER BY order_date;
