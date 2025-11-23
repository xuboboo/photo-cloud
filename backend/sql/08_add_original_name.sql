-- ============================================
-- 添加原始文件名字段（支持中文显示）
-- ============================================

-- 1. 添加 original_name 字段
ALTER TABLE files 
ADD COLUMN IF NOT EXISTS original_name text;

-- 2. 更新现有文件的 original_name（使用 name 字段）
UPDATE files 
SET original_name = name 
WHERE original_name IS NULL;

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_files_original_name ON files(original_name);

-- 4. 验证
SELECT 
  id,
  name,
  original_name,
  type,
  created_at
FROM files
ORDER BY created_at DESC
LIMIT 10;
