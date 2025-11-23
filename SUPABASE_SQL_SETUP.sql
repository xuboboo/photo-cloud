-- ============================================
-- Supabase 数据库完整配置脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 第一步：创建文件表
-- ============================================

CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  path text NOT NULL,
  name text NOT NULL,
  type text NOT NULL,
  size int,
  created_at timestamp with time zone DEFAULT now()
);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_files_user_id ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON files(created_at DESC);

-- 第二步：启用行级安全策略
-- ============================================

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- 第三步：删除可能存在的旧策略（避免冲突）
-- ============================================

DROP POLICY IF EXISTS "user_select_own_files" ON files;
DROP POLICY IF EXISTS "user_insert_own_files" ON files;
DROP POLICY IF EXISTS "user_delete_own_files" ON files;
DROP POLICY IF EXISTS "user_update_own_files" ON files;

-- 第四步：创建新的安全策略
-- ============================================

-- 用户只能查看自己的文件
CREATE POLICY "user_select_own_files" 
ON files FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- 用户只能插入自己的文件
CREATE POLICY "user_insert_own_files" 
ON files FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- 用户只能删除自己的文件
CREATE POLICY "user_delete_own_files"
ON files FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 用户只能更新自己的文件
CREATE POLICY "user_update_own_files"
ON files FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 配置完成！
-- ============================================

-- 验证配置（可选）
-- 查看创建的表
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'files';

-- 查看创建的策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'files';
