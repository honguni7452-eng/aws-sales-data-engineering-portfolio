-- Lab1-03. 고객·상품 집계 분석

-- 1) 고객별 총 구매금액과 주문 수
SELECT
    customer_id,
    ROUND(SUM(amount), 2) AS total_purchase_amount,
    COUNT(*) AS order_count
FROM sales_db.sales
GROUP BY customer_id
ORDER BY total_purchase_amount DESC, customer_id;

-- 2) 매출 상위 고객 10명
SELECT
    customer_id,
    ROUND(SUM(amount), 2) AS total_purchase_amount
FROM sales_db.sales
GROUP BY customer_id
ORDER BY total_purchase_amount DESC, customer_id
LIMIT 10;

-- 3) 상품별 총매출과 주문 수
SELECT
    product_id,
    ROUND(SUM(amount), 2) AS product_sales,
    COUNT(*) AS order_count
FROM sales_db.sales
GROUP BY product_id
ORDER BY product_sales DESC, product_id;

-- 4) 가장 많이 팔린 상품: 주문 건수 기준
SELECT
    product_id,
    COUNT(*) AS order_count
FROM sales_db.sales
GROUP BY product_id
ORDER BY order_count DESC, product_id
LIMIT 1;

-- 5) 상품별 매출 순위
WITH product_sales AS (
    SELECT
        product_id,
        SUM(amount) AS total_sales
    FROM sales_db.sales
    GROUP BY product_id
)
SELECT
    product_id,
    ROUND(total_sales, 2) AS total_sales,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM product_sales
ORDER BY sales_rank, product_id;

-- 6) 고객별 총 구매금액이 고객 평균 총 구매금액보다 높은 고객 수
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(amount) AS total_sales
    FROM sales_db.sales
    GROUP BY customer_id
),
average_customer_sales AS (
    SELECT AVG(total_sales) AS average_sales
    FROM customer_sales
)
SELECT COUNT(*) AS customers_above_average
FROM customer_sales
CROSS JOIN average_customer_sales
WHERE customer_sales.total_sales > average_customer_sales.average_sales;
