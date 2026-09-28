-- Lab1-04. 날짜 기반 분석

-- 1) 최근 30일 주문
SELECT *
FROM sales_db.sales
WHERE order_date >= current_date - INTERVAL '30' DAY
ORDER BY order_date DESC, order_id;

-- 2) 일별 매출과 주문 수
SELECT
    order_date,
    ROUND(SUM(amount), 2) AS daily_sales,
    COUNT(*) AS order_count
FROM sales_db.sales
GROUP BY order_date
ORDER BY order_date;

-- 3) 요일별 매출
-- day_of_week: 월요일=1, 일요일=7
SELECT
    day_of_week(order_date) AS weekday_number,
    CASE day_of_week(order_date)
        WHEN 1 THEN '월요일'
        WHEN 2 THEN '화요일'
        WHEN 3 THEN '수요일'
        WHEN 4 THEN '목요일'
        WHEN 5 THEN '금요일'
        WHEN 6 THEN '토요일'
        WHEN 7 THEN '일요일'
    END AS weekday_name,
    ROUND(SUM(amount), 2) AS weekday_sales,
    COUNT(*) AS order_count
FROM sales_db.sales
GROUP BY day_of_week(order_date)
ORDER BY weekday_number;
