-- Lab3-02. Bronze 샘플 데이터 3행 입력 및 조회

INSERT INTO commerce_lakehouse.bronze_orders
    (order_id, customer_id, product_id, amount, order_ts)
VALUES
    (1, 100, 10, DECIMAL '120.50', TIMESTAMP '2026-08-17 10:00:00'),
    (2, 101, 20, DECIMAL '80.00',  TIMESTAMP '2026-08-17 10:05:00'),
    (3, 100, 30, DECIMAL '300.00', TIMESTAMP '2026-08-17 10:10:00');

SELECT *
FROM commerce_lakehouse.bronze_orders
ORDER BY order_id;

SELECT COUNT(*) AS bronze_row_count
FROM commerce_lakehouse.bronze_orders;
