# Lab3 - Apache Iceberg Lakehouse

## 1. 실습 제목과 목표

**Apache Iceberg Lakehouse**

기존에는 Data Lake와 Data Warehouse가 별도로 존재했다면, Lab3의 목표는 `S3 + Iceberg + SQL Engine(Athena)` 조합으로 저렴한 객체 스토리지 위에서도 테이블 트랜잭션과 변경 이력을 관리하는 것입니다.

| 기존 구조 | Lab3 목표 구조 |
| --- | --- |
| Data Lake: 원본 파일 저장 | S3에 원본과 분석 데이터를 계층별 저장 |
| Data Warehouse: 정형 SQL 분석 | Athena SQL로 직접 분석 |
| 파일 수정·삭제·이력 관리가 어려움 | Iceberg Snapshot, ACID, Time Travel 적용 |

## 2. AWS 구조

```text
s3://<YOUR-BUCKET>/
├── bronze/  원본 보존
├── silver/  정제 데이터
└── gold/    고객별 분석용 집계

AWS Glue Data Catalog / Athena
└── commerce_lakehouse
    ├── bronze_orders
    ├── silver_orders
    └── gold_customer_summary
```

Athena Workgroup은 Engine version 3을 사용합니다.

## 3. Bronze·Silver·Gold 역할

| 계층 | 역할 | 이 실습의 테이블 |
| --- | --- | --- |
| Bronze | 원본을 최대한 그대로 보존 | `bronze_orders` |
| Silver | 분석 가능한 타입으로 변환하고 품질 조건 적용 | `silver_orders` |
| Gold | 비즈니스에서 바로 사용할 고객 단위 집계 | `gold_customer_summary` |

## 4. SQL 실행 순서

| 순서 | 파일 | 내용 |
| --- | --- | --- |
| 1 | `01_create_database_and_bronze.sql` | DB와 Bronze Iceberg 테이블 생성 |
| 2 | `02_insert_and_query_bronze.sql` | 샘플 3행 입력·조회 |
| 3 | `03_acid_update_delete.sql` | UPDATE·DELETE 트랜잭션 |
| 4 | `04_snapshot_and_time_travel.sql` | Snapshot 조회와 과거 버전 조회 |
| 5 | `05_schema_evolution.sql` | 컬럼 추가와 스키마 변경 확인 |
| 6 | `06_iceberg_metadata.sql` | files·manifests·history 등 메타데이터 확인 |
| 7 | `07_dirty_raw_validation.sql` | Dirty Raw 타입 변환·오류 검사 |
| 8 | `08_create_silver_orders.sql` | Silver Iceberg 테이블 생성 |
| 9 | `09_reload_silver_orders.sql` | 네 가지 요구사항에 맞춰 Silver 재적재 |
| 10 | `10_validate_silver_orders.sql` | Silver 정제 결과 검증 |
| 11 | `11_create_gold_customer_summary.sql` | Gold Iceberg 테이블 생성 |
| 12 | `12_reload_and_validate_gold.sql` | 고객별 요약 적재·검증 |
| 13 | `13_table_maintenance.sql` | OPTIMIZE·VACUUM 유지보수 예제 |
| 14 | `14_restore_silver_snapshot_and_rebuild_gold.sql` | 확정 Silver Snapshot 복원·Gold 재생성 |
| 15 | `15_export_portfolio_csv.sql` | Raw·Silver·Gold 결과 CSV 다운로드용 조회 |

## 5. 최종과제의 네 가지 요구사항

사용자가 제시한 네 항목은 실제 계층 역할에 따라 다음처럼 나뉩니다.

1. 중복 `order_id` 제거 → Silver
2. `amount <= 0` 제거 → Silver
3. 고객별 총 구매금액 생성 → Gold
4. 기준일 `2026-08-18`부터 최근 90일 주문만 조회 → Silver

즉 Silver에는 1·2·4번을 적용하고, 3번은 Gold에서 수행합니다. `customer_id IS NULL` 제거는 제시된 네 조건에 없으므로 임의로 다섯 번째 정제 조건에 추가하지 않고 검증 결과로만 표시합니다.

### 실행 시점에 따라 달라지는 조건

이전 실행에서 Silver가 5,246건으로 집계된 원인은 최근 90일 조건의 기준으로 `CURRENT_TIMESTAMP`를 사용했기 때문입니다. 실행 날짜가 바뀌면 90일 구간의 시작점과 끝점도 함께 이동하므로, 같은 원본에 같은 SQL을 실행해도 결과가 달라질 수 있습니다.

재현 가능한 파이프라인에서는 다음 중 하나를 기준으로 고정해야 합니다.

- 배치 기준 날짜를 매개변수나 SQL 리터럴로 고정
- 검증을 마친 Iceberg Snapshot ID를 데이터 버전으로 고정

이 저장소의 재적재 SQL은 기준 날짜를 `2026-08-18`로 고정하고, 최종 결과의 기준은 같은 날 생성된 Silver Snapshot `8329354579635974189`로 고정합니다. 따라서 Lab3의 Silver 최종 주문 수는 5,246건이 아니라 **5,488건**입니다.

## 6. Iceberg에서 확인한 기능

- `INSERT`, `UPDATE`, `DELETE`마다 새로운 Snapshot 생성
- ACID 트랜잭션과 Snapshot Isolation
- `FOR TIMESTAMP AS OF`, `FOR VERSION AS OF`를 이용한 Time Travel
- 데이터 파일을 다시 작성하지 않는 Schema Evolution
- `$files`, `$manifests`, `$history`, `$snapshots` 메타데이터 테이블
- Hidden Partitioning

## 7. Silver Version Travel 복원

`14_restore_silver_snapshot_and_rebuild_gold.sql`은 다음 순서로 확정 Silver를 현재 버전으로 복원합니다.

1. `silver_orders$snapshots`에서 Snapshot 목록과 생성 시각을 확인합니다.
2. `FOR VERSION AS OF 8329354579635974189`로 과거 버전을 직접 집계합니다.
3. 전체 주문 5,488건과 고유 주문 5,488건을 확인합니다.
4. 현재 Silver를 비운 뒤 같은 Snapshot의 여섯 컬럼을 다시 입력합니다.
5. 현재 Silver에서 전체 5,488건, 고유 5,488건, 중복 0건을 재검증합니다.

`DELETE` 이후에도 과거 Snapshot이 만료되지 않았다면 Version Travel로 조회할 수 있습니다. 단, `VACUUM`으로 해당 Snapshot이 만료되면 복원할 수 없으므로 이 절차는 테이블 유지보수 전에 수행해야 합니다.

## 8. Gold 재생성과 정합성 검증

복원한 Silver 5,488건을 기준으로 `gold_customer_summary`를 비우고 고객별 요약을 다시 적재했습니다. 주문 수, 총 구매금액, 평균 주문금액, 고유 상품 수, 최초·최근 주문 시각을 고객 단위로 집계합니다.

검증은 Silver 고객별 재집계 결과와 Gold를 `FULL OUTER JOIN`으로 비교합니다. 최종 결과는 Gold 고객 997명, 중복 고객 0명, 누락 고객 0명, 예상하지 않은 고객 0명, 고객 집계 오류 0건입니다.

## 9. Partition Evolution 주의사항

Apache Iceberg 포맷은 Partition Evolution을 지원하지만, Athena에서는 현재 `ALTER TABLE ADD/DROP PARTITION` 방식의 파티션 변경을 지원하지 않습니다. 이 저장소에서는 실행되지 않는 SQL을 넣지 않고, 테이블 생성 시 `PARTITIONED BY (month(order_timestamp))`를 사용해 Hidden Partitioning을 적용합니다. 실제 Partition Spec 변경은 Spark 등 해당 기능을 지원하는 Iceberg 엔진에서 수행해야 합니다.

## 10. 최종 결과와 데이터 출처

Lab3은 S3를 단순 파일 저장소로 사용하는 단계를 넘어, Iceberg Metadata가 Parquet Data File과 Snapshot을 관리하도록 구성한 Lakehouse 실습입니다. Silver에서 품질을 보장하고 Gold에서 고객 단위 결과를 제공하면서 Data Lake와 SQL 분석 계층을 연결했습니다.

```text
Dirty Raw 11,000건 (sales_db.sales2_dirty_raw)
→ Silver 5,488건 (확정 Snapshot)
→ Gold 고객 요약 997건
```

여기서 11,000건은 Lab2에서 만든 외부 Raw 테이블이며 Bronze 역할을 합니다. `commerce_lakehouse.bronze_orders`는 1~6번 SQL에서 Iceberg의 ACID·Snapshot·Schema Evolution을 확인하기 위한 3행 샘플 테이블이므로, 포트폴리오에서는 둘을 같은 물리 테이블이라고 표현하지 않습니다.

5,488건과 997명은 AWS에서 실행한 Silver Snapshot `8329354579635974189`의 실측 결과입니다. 현재 로컬 Python 생성기는 실행일을 기준으로 최근 90일 데이터를 새로 만들기 때문에, 새로 생성한 CSV에 고정 기준일 `2026-08-18`을 적용하면 같은 행 수가 보장되지 않습니다. 결과 CSV를 증빙으로 보관하려면 15번 SQL을 실행하고 Athena 결과 화면에서 각 결과를 CSV로 다운로드합니다.

2026-08-25에 내려받은 Raw·Silver·Gold CSV와 Athena 실행 화면은 [evidence](evidence)에 보관합니다.

| 검증 항목 | 최종 결과 |
| --- | ---: |
| Silver 전체 주문 | 5,488건 |
| Silver 고유 주문 | 5,488건 |
| Silver 중복 주문 | 0건 |
| Gold 고객 | 997명 |
| Gold 중복 고객 | 0명 |
| Gold 누락 고객 | 0명 |
| Gold 예상하지 않은 고객 | 0명 |
| Gold 고객 집계 오류 | 0건 |

## 11. 공식 참고자료

- [Amazon Athena에서 Iceberg 테이블 생성](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-creating-tables.html)
- [Iceberg Time Travel과 Version Travel](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-time-travel-and-version-travel-queries.html)
- [Iceberg Metadata 테이블 조회](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-table-data.html)
- [Athena Iceberg Schema Evolution](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-evolving-table-schema.html)
- [Iceberg 테이블 최적화](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-data-optimization.html)
