-- ============================================
-- 修复 Storage RLS 策略
-- ============================================

-- 1. 删除所有现有的 Storage 策略
-- ============================================

DROP POLICY IF EXISTS "Users can upload own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;

-- 2. 创建新的 Storage 策略（更宽松但仍然安全）
-- ============================================

-- 允许认证用户上传到 private-files bucket
CREATE POLICY "Authenticated users can upload to private-files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'private-files'
);

-- 允许认证用户查看 private-files bucket 中的文件
CREATE POLICY "Authenticated users can view private-files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'private-files'
);

-- 允许认证用户删除自己的文件
CREATE POLICY "Authenticated users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'private-files'
);

-- 允许认证用户更新自己的文件
CREATE POLICY "Authenticated users can update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'private-files'
);

-- 3. 验证策略
-- ============================================

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- 完成！
-- ============================================

SELECT '✅ Storage 策略已更新' as status;
