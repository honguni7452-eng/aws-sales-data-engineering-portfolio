-- Lab3-03. Iceberg ACID UPDATE와 DELETE
-- 각 DML 문은 하나의 트랜잭션으로 처리되며 새로운 Snapshot을 만든다.

-- 주문 2번의 금액 수정
UPDATE commerce_lakehouse.bronze_orders
SET amount = DECIMAL '100.00'
WHERE order_id = 2;

SELECT *
FROM commerce_lakehouse.bronze_orders
ORDER BY order_id;

-- 주문 3번 삭제
DELETE FROM commerce_lakehouse.bronze_orders
WHERE order_id = 3;

SELECT *
FROM commerce_lakehouse.bronze_orders
ORDER BY order_id;
