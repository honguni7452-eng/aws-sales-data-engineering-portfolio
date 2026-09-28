-- Lab1-06. 고급 분석

-- 1) 매출 상위 10% 고객
-- 고객별 총매출을 기준으로 10개 그룹으로 나누고 첫 번째 그룹을 조회한다.
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(amount) AS total_sales
    FROM sales_db.sales
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_sales,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS sales_group
    FROM customer_sales
)
SELECT
    customer_id,
    ROUND(total_sales, 2) AS total_sales
FROM ranked_customers
WHERE sales_group = 1
ORDER BY total_sales DESC, customer_id;

-- 2) 각 상품에서 가장 비싼 주문 1건
WITH ranked_orders AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        amount,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY amount DESC, order_id
        ) AS row_num
    FROM sales_db.sales
)
SELECT order_id, customer_id, product_id, amount, order_date
FROM ranked_orders
WHERE row_num = 1
ORDER BY product_id;
