-- Lab3-11. 고객별 Gold 요약 Iceberg 테이블 생성

CREATE TABLE commerce_lakehouse.gold_customer_summary (
    customer_id BIGINT,
    order_count BIGINT,
    total_purchase_amount DECIMAL(20, 2),
    average_order_amount DECIMAL(20, 2),
    distinct_product_count BIGINT,
    first_order_timestamp TIMESTAMP,
    last_order_timestamp TIMESTAMP
)
LOCATION 's3://<YOUR-BUCKET>/gold/customer_summary/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet'
);

DESCRIBE commerce_lakehouse.gold_customer_summary;
