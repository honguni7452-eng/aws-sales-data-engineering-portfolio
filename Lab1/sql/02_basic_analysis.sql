-- Lab1-02. 기본 집계 분석

-- 1) 전체 매출과 주문 수
SELECT
    ROUND(SUM(amount), 2) AS total_sales,
    COUNT(*) AS total_orders
FROM sales_db.sales;

-- 2) 평균 주문 금액
SELECT ROUND(AVG(amount), 2) AS average_order_amount
FROM sales_db.sales;

-- 3) 가장 비싼 주문 1건
SELECT order_id, customer_id, product_id, amount, order_date
FROM sales_db.sales
ORDER BY amount DESC, order_id
LIMIT 1;

-- 4) 가장 저렴한 주문 1건
SELECT order_id, customer_id, product_id, amount, order_date
FROM sales_db.sales
ORDER BY amount, order_id
LIMIT 1;

-- 5) 상품은 총 몇 개 존재하는가
SELECT COUNT(DISTINCT product_id) AS product_count
FROM sales_db.sales;

-- 6) 고객은 총 몇 명인가
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM sales_db.sales;
