-- Lab3-04. Snapshot과 Time Travel

-- 1) Snapshot 목록 확인
SELECT
    committed_at,
    snapshot_id,
    parent_id,
    operation,
    summary
FROM "commerce_lakehouse"."bronze_orders$snapshots"
ORDER BY committed_at;

-- 2) 현재 데이터
SELECT *
FROM commerce_lakehouse.bronze_orders
ORDER BY order_id;

-- 3) Timestamp 기준 과거 조회 예시
-- 아래 시각은 실제 Snapshot의 committed_at 사이 시각으로 변경한 뒤 주석을 해제한다.
-- SELECT *
-- FROM commerce_lakehouse.bronze_orders
-- FOR TIMESTAMP AS OF TIMESTAMP '2026-08-17 10:15:00 UTC'
-- ORDER BY order_id;

-- 4) Snapshot ID 기준 과거 조회 예시
-- <SNAPSHOT_ID>를 위 결과의 실제 BIGINT 값으로 바꾼 뒤 주석을 해제한다.
-- SELECT *
-- FROM commerce_lakehouse.bronze_orders
-- FOR VERSION AS OF <SNAPSHOT_ID>
-- ORDER BY order_id;
