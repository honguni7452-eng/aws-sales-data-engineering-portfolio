-- Lab3-13. Iceberg 테이블 유지보수
-- Time Travel 학습과 검증을 마친 뒤 필요할 때만 실행한다.
-- 특히 14번의 Snapshot 확인·복원이 끝나기 전에는 VACUUM 주석을 해제하지 않는다.

-- 현재 파일 수와 Snapshot을 먼저 확인한다.
SELECT * FROM "commerce_lakehouse"."silver_orders$files";
SELECT * FROM "commerce_lakehouse"."silver_orders$snapshots" ORDER BY committed_at;

-- 작은 Data File을 합쳐 읽기 효율을 높인다.
-- OPTIMIZE commerce_lakehouse.silver_orders REWRITE DATA USING BIN_PACK;

-- 오래된 Snapshot과 Orphan File을 정리한다.
-- 주의: 제거된 Snapshot으로는 더 이상 Time Travel을 할 수 없다.
-- VACUUM commerce_lakehouse.silver_orders;

-- Gold에도 같은 방식으로 적용할 수 있다.
-- OPTIMIZE commerce_lakehouse.gold_customer_summary REWRITE DATA USING BIN_PACK;
-- VACUUM commerce_lakehouse.gold_customer_summary;
