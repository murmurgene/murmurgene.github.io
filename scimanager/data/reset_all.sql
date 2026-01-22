-- [Supabase 완전 초기화 스크립트]
-- 주의: 이 스크립트는 모든 데이터와 스토리지 파일을 영구적으로 삭제합니다.

-- 1. Public 스키마 초기화 (테이블/뷰/함수 삭제)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- 2. Storage 초기화 (모든 파일 및 버킷 삭제)
-- storage 스키마는 삭제하면 안 되므로, 내용물만 비웁니다.
-- objects(파일)가 buckets(버킷)을 참조하므로 CASCADE로 자동 삭제될 수 있으나, 명시적으로 지웁니다.
DELETE FROM storage.objects;
DELETE FROM storage.buckets;

-- 초기화 완료 후 schema.sql을 실행하여 테이블과 버킷을 다시 생성하세요.
