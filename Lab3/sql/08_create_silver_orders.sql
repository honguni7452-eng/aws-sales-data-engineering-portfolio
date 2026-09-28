-- Lab3-08. Silver Iceberg 테이블 생성

CREATE TABLE commerce_lakehouse.silver_orders (
    order_id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    amount DECIMAL(10, 2),
    order_timestamp TIMESTAMP,
    customer_total_amount DECIMAL(20, 2)
)
PARTITIONED BY (month(order_timestamp))
LOCATION 's3://<YOUR-BUCKET>/silver/orders/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);

DESCRIBE commerce_lakehouse.silver_orders;
