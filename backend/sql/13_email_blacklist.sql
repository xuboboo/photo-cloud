-- ============================================
-- 邮箱黑名单功能（防止恶意注册和盗刷）
-- ============================================

-- 1. 创建邮箱黑名单表
-- ============================================

CREATE TABLE IF NOT EXISTS email_blacklist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  reason text, -- 拉黑原因
  blocked_by uuid REFERENCES auth.users(id) ON DELETE SET NULL, -- 操作的管理员
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_email_blacklist_email ON email_blacklist(email);
CREATE INDEX IF NOT EXISTS idx_email_blacklist_created_at ON email_blacklist(created_at DESC);

-- 启用 RLS
ALTER TABLE email_blacklist ENABLE ROW LEVEL SECURITY;

-- 管理员可以查看黑名单
CREATE POLICY "Admins can view blacklist"
ON email_blacklist FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 管理员可以添加黑名单
CREATE POLICY "Admins can insert blacklist"
ON email_blacklist FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 管理员可以更新黑名单
CREATE POLICY "Admins can update blacklist"
ON email_blacklist FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 管理员可以删除黑名单
CREATE POLICY "Admins can delete blacklist"
ON email_blacklist FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 2. 创建检查邮箱是否在黑名单的函数
-- ============================================

CREATE OR REPLACE FUNCTION is_email_blacklisted(check_email text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM email_blacklist
    WHERE LOWER(email) = LOWER(check_email)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION is_email_blacklisted TO anon, authenticated;

-- 3. 添加邮箱到黑名单
-- ============================================

CREATE OR REPLACE FUNCTION add_email_to_blacklist(
  target_email text,
  block_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
  existing_user uuid;
BEGIN
  -- 检查调用者是否是管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '只有管理员才能添加黑名单'
    );
  END IF;
  
  -- 检查邮箱是否已在黑名单中
  IF EXISTS (SELECT 1 FROM email_blacklist WHERE LOWER(email) = LOWER(target_email)) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '该邮箱已在黑名单中'
    );
  END IF;
  
  -- 添加到黑名单
  INSERT INTO email_blacklist (email, reason, blocked_by)
  VALUES (LOWER(target_email), block_reason, auth.uid());
  
  -- 检查是否有使用此邮箱的现有用户
  SELECT id INTO existing_user
  FROM auth.users
  WHERE LOWER(email) = LOWER(target_email);
  
  RETURN jsonb_build_object(
    'success', true,
    'message', '邮箱已添加到黑名单',
    'has_existing_user', existing_user IS NOT NULL,
    'existing_user_id', existing_user
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION add_email_to_blacklist TO authenticated;

-- 4. 从黑名单移除邮箱
-- ============================================

CREATE OR REPLACE FUNCTION remove_email_from_blacklist(target_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
BEGIN
  -- 检查调用者是否是管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '只有管理员才能移除黑名单'
    );
  END IF;
  
  -- 从黑名单移除
  DELETE FROM email_blacklist
  WHERE LOWER(email) = LOWER(target_email);
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '该邮箱不在黑名单中'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', '邮箱已从黑名单移除'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION remove_email_from_blacklist TO authenticated;

-- 5. 批量添加邮箱到黑名单
-- ============================================

CREATE OR REPLACE FUNCTION batch_add_emails_to_blacklist(
  emails_json jsonb,
  block_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
  email_item text;
  added_count integer := 0;
  skipped_count integer := 0;
BEGIN
  -- 检查调用者是否是管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '只有管理员才能添加黑名单'
    );
  END IF;
  
  -- 遍历邮箱列表
  FOR email_item IN SELECT jsonb_array_elements_text(emails_json)
  LOOP
    -- 检查是否已存在
    IF NOT EXISTS (SELECT 1 FROM email_blacklist WHERE LOWER(email) = LOWER(email_item)) THEN
      INSERT INTO email_blacklist (email, reason, blocked_by)
      VALUES (LOWER(email_item), block_reason, auth.uid());
      added_count := added_count + 1;
    ELSE
      skipped_count := skipped_count + 1;
    END IF;
  END LOOP;
  
  RETURN jsonb_build_object(
    'success', true,
    'added_count', added_count,
    'skipped_count', skipped_count,
    'message', format('成功添加 %s 个邮箱，跳过 %s 个已存在的邮箱', added_count, skipped_count)
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION batch_add_emails_to_blacklist TO authenticated;

-- 6. 获取黑名单统计信息
-- ============================================

CREATE OR REPLACE FUNCTION get_blacklist_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
  total_count integer;
  today_count integer;
  week_count integer;
BEGIN
  -- 检查调用者是否是管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '只有管理员才能查看统计信息'
    );
  END IF;
  
  -- 统计总数
  SELECT COUNT(*) INTO total_count FROM email_blacklist;
  
  -- 统计今天添加的
  SELECT COUNT(*) INTO today_count 
  FROM email_blacklist 
  WHERE created_at >= CURRENT_DATE;
  
  -- 统计本周添加的
  SELECT COUNT(*) INTO week_count 
  FROM email_blacklist 
  WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';
  
  RETURN jsonb_build_object(
    'success', true,
    'total_count', total_count,
    'today_count', today_count,
    'week_count', week_count
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_blacklist_stats TO authenticated;

-- 7. 创建触发器：阻止黑名单邮箱注册
-- ============================================

-- 注意：这个触发器需要在用户创建之前检查
-- 由于 Supabase Auth 的限制，我们需要在应用层面进行检查
-- 这里提供一个检查函数供前端调用

CREATE OR REPLACE FUNCTION check_email_before_signup(check_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM email_blacklist WHERE LOWER(email) = LOWER(check_email)) THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'message', '该邮箱已被禁止注册，如有疑问请联系管理员'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'allowed', true,
    'message', '邮箱可以注册'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION check_email_before_signup TO anon, authenticated;

-- 8. 创建视图：黑名单详情（包含管理员信息）
-- ============================================

CREATE OR REPLACE VIEW blacklist_details AS
SELECT 
  eb.id,
  eb.email,
  eb.reason,
  eb.created_at,
  eb.blocked_by,
  u.email as blocked_by_email,
  up.display_name as blocked_by_name
FROM email_blacklist eb
LEFT JOIN auth.users u ON u.id = eb.blocked_by
LEFT JOIN user_profiles up ON up.id = eb.blocked_by;

-- ============================================
-- 使用说明
-- ============================================

-- 1. 检查邮箱是否在黑名单：
--    SELECT is_email_blacklisted('example@example.com');

-- 2. 添加邮箱到黑名单：
--    SELECT add_email_to_blacklist('spam@example.com', '恶意注册');

-- 3. 移除黑名单：
--    SELECT remove_email_from_blacklist('spam@example.com');

-- 4. 批量添加：
--    SELECT batch_add_emails_to_blacklist('["spam1@example.com", "spam2@example.com"]'::jsonb, '批量拉黑');

-- 5. 注册前检查：
--    SELECT check_email_before_signup('newuser@example.com');

-- 6. 查看统计：
--    SELECT get_blacklist_stats();

-- ============================================
-- 验证配置
-- ============================================

SELECT 
  'email_blacklist' as table_name, 
  COUNT(*) as row_count 
FROM email_blacklist;

-- 验证函数
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%blacklist%'
ORDER BY routine_name;
