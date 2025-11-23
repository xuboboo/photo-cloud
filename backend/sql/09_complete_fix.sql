-- ============================================
-- 完整修复脚本 - 一次性解决所有问题
-- ============================================

-- 1. 添加 original_name 字段到 files 表
-- ============================================
ALTER TABLE files 
ADD COLUMN IF NOT EXISTS original_name text;

-- 更新现有文件
UPDATE files 
SET original_name = name 
WHERE original_name IS NULL;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_files_original_name ON files(original_name);

-- 2. 为所有现有用户创建 user_profiles
-- ============================================
INSERT INTO user_profiles (id, role, is_active, storage_quota, storage_used)
SELECT 
  u.id,
  'user' as role,
  true as is_active,
  104857600 as storage_quota,  -- 100MB
  COALESCE((SELECT SUM(size) FROM files WHERE user_id = u.id), 0) as storage_used
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM user_profiles up WHERE up.id = u.id
)
ON CONFLICT (id) DO NOTHING;

-- 3. 将第一个用户设为超级管理员（如果还没有超级管理员）
-- ============================================
DO $$
DECLARE
  first_user_id uuid;
  has_super_admin boolean;
BEGIN
  -- 检查是否已有超级管理员
  SELECT EXISTS (
    SELECT 1 FROM user_profiles WHERE role = 'super_admin'
  ) INTO has_super_admin;
  
  -- 如果没有超级管理员，将第一个用户设为超级管理员
  IF NOT has_super_admin THEN
    SELECT id INTO first_user_id
    FROM auth.users
    ORDER BY created_at ASC
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
      UPDATE user_profiles
      SET role = 'super_admin'
      WHERE id = first_user_id;
      
      RAISE NOTICE 'User % has been set as super admin', first_user_id;
    END IF;
  END IF;
END $$;

-- 4. 重新创建触发器（确保新用户自动创建 profile）
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, is_active, storage_quota, storage_used)
  VALUES (NEW.id, 'user', true, 104857600, 0)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Failed to create user profile: %', SQLERRM;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION create_user_profile();

-- 5. 验证配置
-- ============================================

-- 检查所有用户是否都有 profile
SELECT 
  COUNT(DISTINCT u.id) as total_users,
  COUNT(DISTINCT up.id) as users_with_profile,
  COUNT(DISTINCT u.id) - COUNT(DISTINCT up.id) as missing_profiles
FROM auth.users u
LEFT JOIN user_profiles up ON up.id = u.id;

-- 显示所有用户的完整信息
SELECT 
  u.id,
  u.email,
  up.role,
  up.is_active,
  up.storage_quota / 1024 / 1024 as quota_mb,
  up.storage_used / 1024 / 1024 as used_mb,
  u.created_at,
  CASE 
    WHEN up.id IS NULL THEN '❌ 缺失 profile'
    ELSE '✅ 正常'
  END as status
FROM auth.users u
LEFT JOIN user_profiles up ON up.id = u.id
ORDER BY u.created_at;

-- 检查 files 表的 original_name 字段
SELECT 
  COUNT(*) as total_files,
  COUNT(original_name) as files_with_original_name,
  COUNT(*) - COUNT(original_name) as missing_original_name
FROM files;

-- 显示最近的文件
SELECT 
  id,
  name,
  original_name,
  type,
  size,
  created_at
FROM files
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 完成！
-- ============================================

-- 最终检查
SELECT 
  '✅ 配置完成' as status,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM user_profiles) as total_profiles,
  (SELECT COUNT(*) FROM user_profiles WHERE role = 'super_admin') as super_admins,
  (SELECT COUNT(*) FROM files) as total_files;
