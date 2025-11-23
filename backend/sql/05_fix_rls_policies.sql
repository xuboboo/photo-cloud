-- ============================================
-- 修复 RLS 策略的循环引用问题
-- ============================================

-- 1. 删除所有 user_profiles 的策略
-- ============================================

DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON user_profiles;

-- 2. 重新创建正确的策略（避免循环引用）
-- ============================================

-- 用户可以查看自己的配置（直接使用 auth.uid()）
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 用户可以更新自己的配置（但不能修改 role 和 is_active）
-- 使用子查询避免循环引用
CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND
  role = (SELECT role FROM user_profiles WHERE id = auth.uid() LIMIT 1) AND
  is_active = (SELECT is_active FROM user_profiles WHERE id = auth.uid() LIMIT 1)
);

-- 管理员可以查看所有用户配置
-- 使用 auth.jwt() 来检查角色，避免循环引用
CREATE POLICY "Admins can view all profiles"
ON user_profiles FOR SELECT
TO authenticated
USING (
  (auth.jwt()->>'role')::text = 'authenticated' AND
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN ('admin', 'super_admin')
    LIMIT 1
  )
);

-- 管理员可以更新用户配置
CREATE POLICY "Admins can update profiles"
ON user_profiles FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN ('admin', 'super_admin')
    LIMIT 1
  )
);

-- 3. 修复 activity_logs 的策略
-- ============================================

DROP POLICY IF EXISTS "Users can view own logs" ON activity_logs;
DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;
DROP POLICY IF EXISTS "Authenticated users can insert logs" ON activity_logs;

-- 用户可以查看自己的日志
CREATE POLICY "Users can view own logs"
ON activity_logs FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 管理员可以查看所有日志
CREATE POLICY "Admins can view all logs"
ON activity_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() 
    AND role IN ('admin', 'super_admin')
    LIMIT 1
  )
);

-- 所有认证用户可以插入日志
CREATE POLICY "Authenticated users can insert logs"
ON activity_logs FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 4. 创建一个安全的函数来检查用户角色
-- ============================================

-- 创建一个函数来安全地获取用户角色
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM user_profiles WHERE id = user_id LIMIT 1;
$$;

-- 创建一个函数来检查是否是管理员
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE id = user_id 
    AND role IN ('admin', 'super_admin')
  );
$$;

-- 5. 使用函数重新创建管理员策略（更安全）
-- ============================================

DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON user_profiles;

-- 管理员可以查看所有用户配置（使用函数）
CREATE POLICY "Admins can view all profiles"
ON user_profiles FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

-- 管理员可以更新用户配置（使用函数）
CREATE POLICY "Admins can update profiles"
ON user_profiles FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()));

-- 同样更新 activity_logs 的管理员策略
DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;

CREATE POLICY "Admins can view all logs"
ON activity_logs FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

-- ============================================
-- 修复完成！
-- ============================================

-- 验证策略
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'activity_logs')
ORDER BY tablename, policyname;
