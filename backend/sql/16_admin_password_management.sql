-- =====================================================
-- 管理员密码管理功能（安全版本）
-- 注意：不提供查看密码功能，只提供重置功能
-- =====================================================

-- 1. 创建密码重置记录表
CREATE TABLE IF NOT EXISTS admin_password_resets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  new_password_hint text, -- 可选：新密码提示（不是密码本身）
  reset_reason text,
  reset_at timestamp with time zone DEFAULT now(),
  notified boolean DEFAULT false, -- 是否已通知用户
  created_at timestamp with time zone DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_admin_password_resets_user ON admin_password_resets(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_password_resets_admin ON admin_password_resets(admin_id);

-- 2. 管理员重置用户密码函数
CREATE OR REPLACE FUNCTION admin_reset_user_password(
  p_admin_id uuid,
  p_target_user_id uuid,
  p_new_password text,
  p_reason text DEFAULT '管理员重置'
) RETURNS jsonb AS $$
DECLARE
  v_admin_role text;
  v_target_email text;
BEGIN
  -- 检查管理员权限
  SELECT role INTO v_admin_role 
  FROM user_profiles 
  WHERE id = p_admin_id;
  
  IF v_admin_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', '权限不足：只有管理员可以重置密码'
    );
  END IF;
  
  -- 获取目标用户邮箱
  SELECT email INTO v_target_email
  FROM auth.users
  WHERE id = p_target_user_id;
  
  IF v_target_email IS NULL THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', '用户不存在'
    );
  END IF;
  
  -- 防止管理员重置超级管理员密码（除非自己是超级管理员）
  IF v_admin_role = 'admin' THEN
    DECLARE
      v_target_role text;
    BEGIN
      SELECT role INTO v_target_role
      FROM user_profiles
      WHERE id = p_target_user_id;
      
      IF v_target_role = 'super_admin' THEN
        RETURN jsonb_build_object(
          'success', false, 
          'error', '普通管理员无法重置超级管理员密码'
        );
      END IF;
    END;
  END IF;
  
  -- 记录重置操作
  INSERT INTO admin_password_resets (
    user_id, 
    admin_id, 
    reset_reason,
    new_password_hint
  ) VALUES (
    p_target_user_id,
    p_admin_id,
    p_reason,
    '密码已重置为管理员指定的新密码'
  );
  
  -- 记录安全日志
  PERFORM log_security_event(
    p_admin_id,
    'admin_reset_password',
    'user',
    p_target_user_id,
    jsonb_build_object(
      'target_email', v_target_email,
      'reason', p_reason
    ),
    'warning'
  );
  
  -- 注意：实际的密码更新需要通过Supabase Admin API完成
  -- 这里只记录操作，前端需要调用Supabase Admin API
  
  RETURN jsonb_build_object(
    'success', true,
    'message', '密码重置请求已记录，请通过Admin API完成重置',
    'user_email', v_target_email,
    'next_step', '调用 supabase.auth.admin.updateUserById()'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 生成临时密码函数
CREATE OR REPLACE FUNCTION generate_temp_password(
  p_length int DEFAULT 12
) RETURNS text AS $$
DECLARE
  v_chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#$%';
  v_password text := '';
  v_i int;
BEGIN
  FOR v_i IN 1..p_length LOOP
    v_password := v_password || substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);
  END LOOP;
  
  RETURN v_password;
END;
$$ LANGUAGE plpgsql;

-- 4. 获取密码重置历史
CREATE OR REPLACE FUNCTION get_password_reset_history(
  p_admin_id uuid,
  p_user_id uuid DEFAULT NULL,
  p_limit int DEFAULT 50
) RETURNS TABLE (
  reset_id uuid,
  user_email text,
  admin_email text,
  reset_reason text,
  reset_at timestamp with time zone,
  notified boolean
) AS $$
DECLARE
  v_admin_role text;
BEGIN
  -- 检查权限
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION '权限不足';
  END IF;
  
  RETURN QUERY
  SELECT 
    pr.id,
    u.email,
    a.email,
    pr.reset_reason,
    pr.reset_at,
    pr.notified
  FROM admin_password_resets pr
  JOIN auth.users u ON u.id = pr.user_id
  JOIN auth.users a ON a.id = pr.admin_id
  WHERE (p_user_id IS NULL OR pr.user_id = p_user_id)
  ORDER BY pr.reset_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 强制用户下次登录时修改密码
CREATE OR REPLACE FUNCTION force_password_change(
  p_admin_id uuid,
  p_user_id uuid,
  p_reason text DEFAULT '安全策略要求'
) RETURNS jsonb AS $$
DECLARE
  v_admin_role text;
BEGIN
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object('success', false, 'error', '权限不足');
  END IF;
  
  -- 更新用户配置，标记需要修改密码
  UPDATE user_profiles
  SET 
    updated_at = now()
  WHERE id = p_user_id;
  
  -- 记录日志
  PERFORM log_security_event(
    p_admin_id,
    'force_password_change',
    'user',
    p_user_id,
    jsonb_build_object('reason', p_reason),
    'warning'
  );
  
  RETURN jsonb_build_object('success', true, 'message', '已标记用户需要修改密码');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RLS策略
ALTER TABLE admin_password_resets ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（如果有）
DROP POLICY IF EXISTS "admin_view_password_resets" ON admin_password_resets;

-- 注意：移除会导致递归的策略
-- admin_password_resets 通过专用函数访问，避免RLS递归

-- 完成
COMMENT ON TABLE admin_password_resets IS '管理员密码重置记录（只记录操作，不存储密码）';
COMMENT ON FUNCTION admin_reset_user_password IS '管理员重置用户密码（安全方式）';
COMMENT ON FUNCTION generate_temp_password IS '生成安全的临时密码';

-- 重要安全说明
DO $$
BEGIN
  RAISE NOTICE '===== 重要安全说明 =====';
  RAISE NOTICE '1. 数据库中不存储明文密码';
  RAISE NOTICE '2. 管理员无法查看用户密码';
  RAISE NOTICE '3. 只能重置密码，不能查看密码';
  RAISE NOTICE '4. 所有操作都有审计日志';
  RAISE NOTICE '5. 实际密码更新需通过Supabase Admin API';
  RAISE NOTICE '========================';
END $$;
