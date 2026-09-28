from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = (
    SparkSession.builder
    .appName("silver-transform")
    .getOrCreate()
)

bronze_df = spark.sql("""
SELECT *
FROM commerce_lakehouse.bronze_orders
""")

# Null 제거
silver_df = bronze_df.filter(
    col("customer_id").isNotNull()
)

# 잘못된 금액 제거
silver_df = silver_df.filter(
    col("amount") > 0
)

# 중복제거
silver_df = silver_df.dropDuplicates(
    ["order_id"]
)

# 데이터 컬럼 추가
silver_df = silver_df.withColumn(
    "order_date",
    to_date("order_timestamp")
)

silver_df = (
    silver_df
    .withColumn("order_year", year("order_date"))
    .withColumn("order_month", month("order_date"))
    .withColumn("order_week", weekofyear("order_date"))
)

#iceberg 저장
silver_df.writeTo(
    "commerce_lakehouse.silver_orders"
)\
.tableProperty(
    "format-version",
    "2"
)\
.createOrReplace()

gold_df = (
    silver_df
    .groupBy("customer_id")
    .agg(
        count("*").alias("total_orders"),
        sum("amount").alias("total_amount"),
        min("order_date").alias("first_order_date"),
        max("order_date").alias("last_order_date")
    )
)

gold_df.writeTo(
    "commerce_lakehouse.gold_customer_summary"
)\
.createOrReplace()

# 상품 분석 Gold Table 생성
product_gold_df = (
    silver_df
    .groupBy("product_id")
    .agg(
        count("*").alias("total_orders"),
        sum("amount").alias("total_sales"),
        avg("amount").alias("avg_order_amount")
    )
)

product_gold_df.writeTo(
    "commerce_lakehouse.gold_product_sales"
)\
.createOrReplace()

# 일별 매출 Table 생성
daily_gold_df = (
    silver_df
    .groupBy("order_date")
    .agg(
        count("*").alias("orders"),
        sum("amount").alias("revenue")
    )
    .withColumnRenamed("order_date", "date")
)

daily_gold_df.writeTo(
    "commerce_lakehouse.gold_daily_sales"
)\
.createOrReplace()
