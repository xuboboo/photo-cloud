-- ============================================
-- 为现有用户创建缺失的 user_profiles
-- ============================================

-- 1. 检查是否有用户没有 profile
-- ============================================

SELECT 
  u.id,
  u.email,
  u.created_at,
  CASE 
    WHEN up.id IS NULL THEN '❌ 缺失 profile'
    ELSE '✅ 已有 profile'
  END as status
FROM auth.users u
LEFT JOIN user_profiles up ON up.id = u.id
ORDER BY u.created_at;

-- 2. 为所有缺失 profile 的用户创建 profile
-- ============================================

INSERT INTO user_profiles (id, role, is_active, storage_quota, storage_used)
SELECT 
  u.id,
  'user' as role,
  true as is_active,
  1073741824 as storage_quota,  -- 1GB
  0 as storage_used
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM user_profiles up WHERE up.id = u.id
);

-- 3. 验证所有用户都有 profile
-- ============================================

SELECT 
  COUNT(DISTINCT u.id) as total_users,
  COUNT(DISTINCT up.id) as users_with_profile,
  COUNT(DISTINCT u.id) - COUNT(DISTINCT up.id) as missing_profiles
FROM auth.users u
LEFT JOIN user_profiles up ON up.id = u.id;

-- 4. 显示所有用户的完整信息
-- ============================================

SELECT 
  u.id,
  u.email,
  up.role,
  up.is_active,
  up.storage_quota,
  up.storage_used,
  u.created_at
FROM auth.users u
LEFT JOIN user_profiles up ON up.id = u.id
ORDER BY u.created_at;
