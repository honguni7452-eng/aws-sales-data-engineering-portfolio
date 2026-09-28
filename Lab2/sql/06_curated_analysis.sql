-- Lab2-06. Lab1의 주요 분석을 Curated 테이블에서 재실행

-- 1) 총매출, 주문 수, 평균 주문 금액
SELECT
    ROUND(SUM(amount), 2) AS total_sales,
    COUNT(*) AS total_orders,
    ROUND(AVG(amount), 2) AS average_order_amount
FROM sales_db.sales2;

-- 2) 고객별 총 구매금액
SELECT
    customer_id,
    ROUND(SUM(amount), 2) AS total_purchase_amount,
    COUNT(*) AS order_count
FROM sales_db.sales2
GROUP BY customer_id
ORDER BY total_purchase_amount DESC, customer_id;

-- 3) 상품별 매출 순위
WITH product_sales AS (
    SELECT product_id, SUM(amount) AS total_sales
    FROM sales_db.sales2
    GROUP BY product_id
)
SELECT
    product_id,
    ROUND(total_sales, 2) AS total_sales,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM product_sales
ORDER BY sales_rank, product_id;

-- 4) 고객별 가장 비싼 주문 1건
WITH ranked_orders AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        amount,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY amount DESC, order_id
        ) AS row_num
    FROM sales_db.sales2
)
SELECT order_id, customer_id, product_id, amount, order_date
FROM ranked_orders
WHERE row_num = 1
ORDER BY customer_id;

-- 5) 일별 누적 매출
WITH daily_sales AS (
    SELECT order_date, SUM(amount) AS sales
    FROM sales_db.sales2
    GROUP BY order_date
)
SELECT
    order_date,
    ROUND(sales, 2) AS daily_sales,
    ROUND(
        SUM(sales) OVER (
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_sales
FROM daily_sales
ORDER BY order_date;

-- 나머지 Lab1 분석 SQL도 테이블명을 sales_db.sales2로 바꿔 동일하게 실행할 수 있다.
