-- Lab3-06. Iceberg Metadata 구조 확인

-- 현재 Data File
SELECT *
FROM "commerce_lakehouse"."bronze_orders$files";

-- Manifest File
SELECT *
FROM "commerce_lakehouse"."bronze_orders$manifests";

-- Snapshot 이력
SELECT *
FROM "commerce_lakehouse"."bronze_orders$snapshots"
ORDER BY committed_at;

-- 현재 Snapshot으로 이어진 이력
SELECT *
FROM "commerce_lakehouse"."bronze_orders$history"
ORDER BY made_current_at;

-- 테이블 Reference
SELECT *
FROM "commerce_lakehouse"."bronze_orders$refs";
