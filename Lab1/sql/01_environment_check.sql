-- Lab1-01. Glue Crawler가 등록한 환경 확인

SHOW DATABASES;

SHOW TABLES IN sales_db;

DESCRIBE sales_db.sales;

SELECT *
FROM sales_db.sales
ORDER BY order_id
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM sales_db.sales;
