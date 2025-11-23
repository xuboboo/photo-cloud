-- =====================================================
-- 邮箱验证管理
-- 用于管理用户邮箱验证状态
-- =====================================================

-- 1. 更新user_statistics视图，添加邮箱验证状态
DROP VIEW IF EXISTS user_statistics;
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
  up.id,
  u.email,
  u.email_confirmed_at,  -- 邮箱验证时间
  CASE 
    WHEN u.email_confirmed_at IS NOT NULL THEN 'verified'
    ELSE 'unverified'
  END as email_status,   -- 邮箱验证状态
  up.display_name,
  up.role,
  up.is_active,
  up.storage_used,
  up.storage_quota,
  up.created_at,
  COUNT(DISTINCT f.id) as file_count,
  COUNT(DISTINCT fs.id) as share_count,
  MAX(al.created_at) as last_activity
FROM user_profiles up
JOIN auth.users u ON u.id = up.id
LEFT JOIN files f ON f.user_id = up.id
LEFT JOIN file_shares fs ON fs.user_id = up.id
LEFT JOIN activity_logs al ON al.user_id = up.id
GROUP BY up.id, u.email, u.email_confirmed_at,
         up.display_name, up.role, up.is_active, 
         up.storage_used, up.storage_quota, up.created_at;

-- 2. 创建管理员手动验证用户邮箱的函数
CREATE OR REPLACE FUNCTION admin_verify_user_email(
  p_admin_id uuid,
  p_target_user_id uuid
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
      'error', '权限不足：只有管理员可以验证邮箱'
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
  
  -- 检查邮箱是否已验证
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = p_target_user_id 
    AND email_confirmed_at IS NOT NULL
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', '该邮箱已经验证过了'
    );
  END IF;
  
  -- 更新邮箱验证状态
  UPDATE auth.users
  SET 
    email_confirmed_at = now()
  WHERE id = p_target_user_id;
  
  -- 记录安全日志
  PERFORM log_security_event(
    p_admin_id,
    'admin_verify_email',
    'user',
    p_target_user_id,
    jsonb_build_object(
      'target_email', v_target_email,
      'method', 'manual_verification'
    ),
    'info'
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', '邮箱验证成功',
    'user_email', v_target_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 创建重发验证邮件的记录函数
CREATE OR REPLACE FUNCTION admin_resend_verification_email(
  p_admin_id uuid,
  p_target_user_id uuid
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
      'error', '权限不足'
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
  
  -- 记录操作日志
  PERFORM log_security_event(
    p_admin_id,
    'admin_resend_verification',
    'user',
    p_target_user_id,
    jsonb_build_object(
      'target_email', v_target_email
    ),
    'info'
  );
  
  -- 注意：实际发送邮件需要通过Supabase Admin API完成
  -- 这里只记录操作
  
  RETURN jsonb_build_object(
    'success', true,
    'message', '验证邮件重发请求已记录',
    'user_email', v_target_email,
    'next_step', '请通过Supabase Dashboard或Admin API发送验证邮件'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 获取未验证用户列表
CREATE OR REPLACE FUNCTION get_unverified_users(
  p_admin_id uuid
) RETURNS TABLE (
  user_id uuid,
  email text,
  display_name text,
  created_at timestamp with time zone,
  days_since_registration int
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
    u.id,
    u.email,
    up.display_name,
    up.created_at,
    EXTRACT(DAY FROM (now() - up.created_at))::int
  FROM auth.users u
  JOIN user_profiles up ON up.id = u.id
  WHERE u.email_confirmed_at IS NULL
  ORDER BY up.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 获取邮箱验证统计
CREATE OR REPLACE FUNCTION get_email_verification_stats(
  p_admin_id uuid
) RETURNS jsonb AS $$
DECLARE
  v_admin_role text;
  v_total_users int;
  v_verified_users int;
  v_unverified_users int;
  v_verification_rate numeric;
BEGIN
  -- 检查权限
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION '权限不足';
  END IF;
  
  -- 统计总用户数
  SELECT COUNT(*) INTO v_total_users
  FROM auth.users;
  
  -- 统计已验证用户数
  SELECT COUNT(*) INTO v_verified_users
  FROM auth.users
  WHERE email_confirmed_at IS NOT NULL;
  
  -- 计算未验证用户数
  v_unverified_users := v_total_users - v_verified_users;
  
  -- 计算验证率
  IF v_total_users > 0 THEN
    v_verification_rate := ROUND((v_verified_users::numeric / v_total_users::numeric * 100), 2);
  ELSE
    v_verification_rate := 0;
  END IF;
  
  RETURN jsonb_build_object(
    'total_users', v_total_users,
    'verified_users', v_verified_users,
    'unverified_users', v_unverified_users,
    'verification_rate', v_verification_rate
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 完成
COMMENT ON FUNCTION admin_verify_user_email IS '管理员手动验证用户邮箱';
COMMENT ON FUNCTION admin_resend_verification_email IS '管理员重发验证邮件';
COMMENT ON FUNCTION get_unverified_users IS '获取未验证用户列表';
COMMENT ON FUNCTION get_email_verification_stats IS '获取邮箱验证统计';

-- 提示
DO $$
BEGIN
  RAISE NOTICE '===== 邮箱验证管理功能 =====';
  RAISE NOTICE '1. 管理员可以查看邮箱验证状态';
  RAISE NOTICE '2. 管理员可以手动验证用户邮箱';
  RAISE NOTICE '3. 管理员可以重发验证邮件';
  RAISE NOTICE '4. 可以查看验证统计和未验证用户列表';
  RAISE NOTICE '========================';
END $$;
