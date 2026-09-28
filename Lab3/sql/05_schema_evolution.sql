-- Lab3-05. Schema Evolution
-- 한 번 실행하는 실습이다. 이미 컬럼이 존재하면 다시 실행하지 않는다.

ALTER TABLE commerce_lakehouse.bronze_orders
ADD COLUMNS (order_status STRING);

SHOW COLUMNS IN commerce_lakehouse.bronze_orders;

UPDATE commerce_lakehouse.bronze_orders
SET order_status = 'COMPLETED'
WHERE order_status IS NULL;

SELECT *
FROM commerce_lakehouse.bronze_orders
ORDER BY order_id;
