-- Lab3-01. Database와 Bronze Iceberg 테이블 생성

CREATE DATABASE IF NOT EXISTS commerce_lakehouse;

CREATE TABLE commerce_lakehouse.bronze_orders (
    order_id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    amount DECIMAL(10, 2),
    order_ts TIMESTAMP
)
LOCATION 's3://<YOUR-BUCKET>/bronze/orders/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);

SHOW TABLES IN commerce_lakehouse;

DESCRIBE commerce_lakehouse.bronze_orders;
