-- ============================================
-- 更新默认存储配额为 100MB
-- ============================================

-- 1. 修改默认配额为 100MB (104857600 bytes)
ALTER TABLE user_profiles 
ALTER COLUMN storage_quota SET DEFAULT 104857600;

-- 2. 更新现有用户的配额为 100MB（如果他们还是 1GB）
UPDATE user_profiles
SET storage_quota = 104857600
WHERE storage_quota = 1073741824;

-- 3. 更新触发器函数
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, is_active, storage_quota, storage_used)
  VALUES (NEW.id, 'user', true, 104857600, 0);  -- 100MB
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Failed to create user profile: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 4. 验证更新
SELECT 
  u.email,
  up.storage_quota / 1024 / 1024 as quota_mb,
  up.storage_used / 1024 / 1024 as used_mb
FROM user_profiles up
JOIN auth.users u ON u.id = up.id;
