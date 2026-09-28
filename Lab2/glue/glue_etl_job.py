"""AWS Glue ETL Job: Dirty CSV를 정제된 Partitioned Parquet으로 변환."""

import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import DateType, DecimalType, LongType


args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "RAW_S3_PATH", "CURATED_S3_PATH"],
)

spark_context = SparkContext()
glue_context = GlueContext(spark_context)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args["JOB_NAME"], args)

raw = (
    spark.read.option("header", "true")
    .option("mode", "PERMISSIVE")
    .csv(args["RAW_S3_PATH"])
)

typed = raw.select(
    F.trim("order_id").cast(LongType()).alias("order_id"),
    F.trim("customer_id").cast(LongType()).alias("customer_id"),
    F.trim("product_id").cast(LongType()).alias("product_id"),
    F.trim("amount").cast(DecimalType(10, 2)).alias("amount"),
    F.trim("order_date").cast(DateType()).alias("order_date"),
)

curated = (
    typed.filter(F.col("order_id").isNotNull())
    .filter(F.col("customer_id").isNotNull())
    .filter(F.col("product_id").isNotNull())
    .filter(F.col("amount") > F.lit(0))
    .filter(F.col("order_date").isNotNull())
    .filter(F.col("order_date") <= F.current_date())
    .dropDuplicates(["order_id"])
)

(
    curated.write.mode("overwrite")
    .format("parquet")
    .partitionBy("order_date")
    .save(args["CURATED_S3_PATH"])
)

job.commit()
