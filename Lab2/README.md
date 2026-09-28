# Lab2 - Glue ETL Dirty-to-Curated Pipeline

## 1. 실습 목표

Lab1의 정상 판매 데이터 10,000행에 오류 데이터 1,000행을 추가하고, AWS Glue ETL Job으로 정제하여 Parquet 및 `order_date` Partition 기반의 Curated 데이터를 만듭니다. 이후 Athena에서 정합성과 성능을 비교합니다.

## 2. Dirty Data 구성

```text
정상 데이터 10,000행
  + 완전 중복 행 500개
  + 오류 행 500개
      - customer_id NULL 165개
      - amount 음수 164개
      - 10년 뒤 미래 날짜 171개
= Dirty Data 11,000행
```

오류 행 500개는 실제 실습 결과와 동일하게 `customer_id NULL` 165개, `amount` 음수 164개, 미래 날짜 171개로 구성합니다.

## 3. 데이터 파이프라인

```text
Lab1 sales_data.csv
    → create_dirty_data.py
    → S3 raw CSV
    → Glue Crawler: sales_db.sales2_dirty_raw
    → Glue ETL Job
    → S3 curated Parquet/order_date=YYYY-MM-DD/
    → Glue Catalog: sales_db.sales2
    → Athena 정합성·성능 비교
```

Lab2의 실제 버킷명이 확정 기록에 남아 있지 않아 `s3://<YOUR-BUCKET>/...`로 표시합니다.

## 4. 정제 조건

1. `order_id` 기준 중복 제거
2. `customer_id IS NULL` 제거
3. `amount <= 0` 제거
4. 현재 날짜보다 미래인 `order_date` 제거
5. 컬럼을 숫자·날짜 타입으로 변환

## 5. 실행 순서

1. Lab1의 `data/sales_data.csv`를 준비합니다.
2. `python/create_dirty_data.py`를 실행합니다.
3. 생성된 `Lab2/data/sales2/sales.csv`를 S3 Raw 경로에 업로드합니다.
4. Glue Crawler로 `sales_db.sales2_dirty_raw`를 등록합니다.
5. `glue/glue_etl_job.py`를 Glue Job에 붙여 넣고 Job Parameter를 설정합니다.
6. Curated 경로를 Crawler로 등록하여 실제 AWS 실습 테이블 `sales_db.sales2`를 만듭니다. Crawler 대상 경로와 설정에 따라 이름이 달라질 수 있으므로 이후 SQL의 테이블명과 일치시킵니다.
7. `sql/` 파일을 순서대로 실행합니다.

### Glue Job Parameter

| 이름 | 예시 |
| --- | --- |
| `--JOB_NAME` | `sales-curated-etl` |
| `--RAW_S3_PATH` | `s3://<YOUR-BUCKET>/raw/sales2/` |
| `--CURATED_S3_PATH` | `s3://<YOUR-BUCKET>/curated/sales/` |

## 6. SQL 파일

| 순서 | 파일 | 내용 |
| --- | --- | --- |
| 1 | `01_dirty_data_validation.sql` | 11,000행과 오류 유형 검사 |
| 2 | `02_curated_validation.sql` | 정제 결과의 품질 조건 검사 |
| 3 | `03_raw_curated_comparison.sql` | 행 수·매출·고객·상품 지표 비교 |
| 4 | `04_data_equality_check.sql` | 정제한 Raw와 Curated의 양방향 차집합 |
| 5 | `05_performance_comparison.sql` | CSV와 Parquet/Partition 스캔 비교 |
| 6 | `06_curated_analysis.sql` | Curated 테이블에서 분석 쿼리 재실행 |

## 7. 성능 비교 방법

동일한 날짜 조건과 동일한 컬럼을 조회한 뒤 Athena 결과 화면의 `Run time`과 `Data scanned`를 기록합니다. 데이터가 10,000행 수준이면 실행 시간 차이는 작을 수 있지만, Parquet은 필요한 컬럼만 읽고 Partition은 불필요한 날짜 폴더를 제외하므로 스캔 용량이 줄어드는 구조를 확인할 수 있습니다.

2026-08-25에 `2026-07-01`의 동일 일 매출 `30,218.81`을 조회한 결과입니다. 쿼리 결과 재사용은 비활성화했습니다.

| 저장 형식 | Run time | Data scanned | Raw 대비 스캔 감소 |
| --- | ---: | ---: | ---: |
| Raw CSV | 537 ms | 327.09 KB | 기준 |
| Partitioned Parquet | 515 ms | 0.57 KB | 약 99.83% |

실행 화면은 [evidence/lab2_csv_performance.png](evidence/lab2_csv_performance.png)와 [evidence/lab2_parquet_performance.png](evidence/lab2_parquet_performance.png)에 보관합니다.

## 8. 결과

Lab2는 단순 조회 가능한 CSV 데이터 레이크를 데이터 품질이 보장되고 분석 비용이 낮은 Curated 계층으로 발전시킨 실습입니다. 다음 Lab3에서는 Apache Iceberg를 적용하여 트랜잭션과 변경 이력을 관리합니다.
