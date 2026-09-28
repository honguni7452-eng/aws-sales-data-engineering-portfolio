-- Lab1-05. Window Function 분석

-- 1) 고객별 가장 비싼 주문 1건
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
    FROM sales_db.sales
)
SELECT order_id, customer_id, product_id, amount, order_date
FROM ranked_orders
WHERE row_num = 1
ORDER BY customer_id;

-- 2) 고객별 첫 주문
WITH ranked_orders AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        amount,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS row_num
    FROM sales_db.sales
)
SELECT order_id, customer_id, product_id, amount, order_date
FROM ranked_orders
WHERE row_num = 1
ORDER BY customer_id;

-- 3) 일별 누적 매출
WITH daily_sales AS (
    SELECT
        order_date,
        SUM(amount) AS sales
    FROM sales_db.sales
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

-- 4) 고객별 누적 구매금액
-- 고객의 주문이 발생할 때마다 누적값이 바뀌므로 customer_id가 여러 행 출력된다.
SELECT
    customer_id,
    order_id,
    order_date,
    amount,
    ROUND(
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_purchase_amount
FROM sales_db.sales
ORDER BY customer_id, order_date, order_id;

-- 5) 고객별 이전 주문과의 금액 차이
WITH order_history AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        amount,
        LAG(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS previous_amount
    FROM sales_db.sales
)
SELECT
    customer_id,
    order_id,
    order_date,
    amount,
    previous_amount,
    ROUND(amount - previous_amount, 2) AS amount_difference
FROM order_history
ORDER BY customer_id, order_date, order_id;
