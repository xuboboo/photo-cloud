-- =====================================================
-- 检查邮箱是否已注册
-- =====================================================

-- 创建函数：检查邮箱是否已存在于 auth.users
CREATE OR REPLACE FUNCTION check_email_exists(check_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count integer;
BEGIN
  -- 检查 auth.users 表中是否存在该邮箱
  SELECT COUNT(*)
  INTO v_count
  FROM auth.users
  WHERE email = lower(check_email);
  
  IF v_count > 0 THEN
    RETURN jsonb_build_object(
      'exists', true,
      'message', '该邮箱已被注册'
    );
  ELSE
    RETURN jsonb_build_object(
      'exists', false,
      'message', '邮箱可用'
    );
  END IF;
END;
$$;

-- 授予权限
GRANT EXECUTE ON FUNCTION check_email_exists(text) TO anon, authenticated;

-- 添加注释
COMMENT ON FUNCTION check_email_exists IS '检查邮箱是否已在 auth.users 中注册';
