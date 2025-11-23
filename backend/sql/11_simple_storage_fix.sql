-- ============================================
-- 简单的 Storage 修复（最宽松的策略）
-- ============================================

-- 删除所有现有策略
DROP POLICY IF EXISTS "Users can upload own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to private-files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view private-files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update own files" ON storage.objects;

-- 创建最简单的策略：所有认证用户可以访问 private-files
CREATE POLICY "Allow all for authenticated users"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'private-files')
WITH CHECK (bucket_id = 'private-files');

-- 验证
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects';
