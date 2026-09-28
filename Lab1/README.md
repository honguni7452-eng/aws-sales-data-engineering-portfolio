# Lab1 - S3, Glue Crawler, Athena Data Lake

## 1. 실습 목표

Python으로 판매 데이터 `sales_data.csv` 10,000행을 생성하고, Amazon S3에 업로드한 뒤 AWS Glue Crawler로 스키마를 등록하여 Amazon Athena SQL로 분석합니다.

## 2. 데이터 구조

| 컬럼 | 의미 | 생성 규칙 |
| --- | --- | --- |
| `order_id` | 주문 고유 번호 | 1부터 10,000까지 증가 |
| `customer_id` | 고객 번호 | 1~1,000 |
| `product_id` | 상품 번호 | 1~50 |
| `amount` | 주문 금액 | 10.00~500.00 |
| `order_date` | 주문일 | 생성 기준일 이전 90일 |

## 3. AWS 구성

```text
sales_data.csv
    → Amazon S3 raw/
    → AWS Glue Crawler
    → Glue Data Catalog: sales_db.sales
    → Amazon Athena SQL 분석
```

Lab1에서 사용한 실제 버킷명이 확정 기록에 남아 있지 않으므로 문서에서는 `s3://<YOUR-BUCKET>/raw/`로 표시합니다. 실제 환경의 버킷명으로 바꿔 사용합니다.

## 4. 실행 순서

1. `python/create_sales_data.py`를 실행해 `data/sales_data.csv`를 생성합니다.
2. `python/validate_sales_data.py`로 행 수, 결측치, 중복, 값 범위를 검사합니다.
3. CSV를 S3의 `raw/` 경로에 업로드합니다.
4. Glue Database `sales_db`와 Crawler를 생성하고 실행합니다.
5. Crawler가 만든 Athena 테이블명이 `sales`인지 확인합니다.
6. `sql/`의 파일을 번호 순서대로 실행합니다.

## 5. SQL 파일

| 순서 | 파일 | 내용 |
| --- | --- | --- |
| 1 | `01_environment_check.sql` | DB·테이블·스키마·샘플 확인 |
| 2 | `02_basic_analysis.sql` | 총매출, 주문 수, 최고·최저 주문 등 |
| 3 | `03_customer_product_analysis.sql` | 고객·상품별 집계와 순위 |
| 4 | `04_date_analysis.sql` | 최근 주문, 일별·요일별 매출 |
| 5 | `05_window_analysis.sql` | 최초·최고 주문, 누적합, 이전 주문 차이 |
| 6 | `06_advanced_analysis.sql` | 상위 10% 고객과 상품별 최고 주문 |

## 6. 핵심 학습 내용

- S3는 파일을 저장하고, Glue Data Catalog는 파일의 스키마를 테이블처럼 관리합니다.
- Athena는 S3 파일을 복사하지 않고 SQL로 직접 조회합니다.
- `GROUP BY`는 고객·상품·날짜 단위 집계에 사용합니다.
- Window Function은 원본 행을 유지하면서 순위, 누적합, 이전 행 비교를 계산합니다.
- 고객별 누적 구매 금액은 고객당 한 행이 아니라 주문 시점마다 누적 결과가 나타납니다. 고객당 최종 합계 한 행이 필요하면 `GROUP BY customer_id`를 사용합니다.

## 7. 결과

Lab1은 CSV 기반 데이터 레이크를 구축하고 Athena로 조회 가능한 상태를 만든 실습입니다. 다음 Lab2에서는 같은 데이터를 Dirty Data로 확장한 뒤 Glue ETL로 정제하고 Parquet으로 최적화합니다.
