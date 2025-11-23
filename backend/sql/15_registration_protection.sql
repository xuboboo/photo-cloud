-- =====================================================
-- 注册保护：防止恶意注册和盗刷
-- =====================================================

-- 1. 创建注册限制表
CREATE TABLE IF NOT EXISTS registration_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier text NOT NULL, -- IP地址或邮箱域名
  limit_type text NOT NULL, -- 'ip', 'email_domain'
  registration_count int DEFAULT 0,
  first_registration_at timestamp with time zone DEFAULT now(),
  last_registration_at timestamp with time zone DEFAULT now(),
  blocked_until timestamp with time zone,
  is_permanently_blocked boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_registration_limits_identifier ON registration_limits(identifier);
CREATE INDEX IF NOT EXISTS idx_registration_limits_type ON registration_limits(limit_type);
CREATE INDEX IF NOT EXISTS idx_registration_limits_blocked ON registration_limits(blocked_until);

-- 2. 创建邮箱验证码表（可选，用于邮箱验证）
CREATE TABLE IF NOT EXISTS email_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  code text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_email_verifications_email ON email_verifications(email);
CREATE INDEX IF NOT EXISTS idx_email_verifications_code ON email_verifications(code);

-- 3. 创建注册限制检查函数
CREATE OR REPLACE FUNCTION check_registration_limit(
  p_ip_address text,
  p_email text,
  p_ip_limit int DEFAULT 5,        -- 每个IP每天最多5个注册
  p_domain_limit int DEFAULT 10    -- 每个邮箱域名每天最多10个注册
) RETURNS jsonb AS $$
DECLARE
  v_email_domain text;
  v_ip_record RECORD;
  v_domain_record RECORD;
  v_window_start timestamp with time zone;
BEGIN
  v_window_start := now() - interval '24 hours';
  
  -- 提取邮箱域名
  v_email_domain := split_part(p_email, '@', 2);
  
  -- 检查IP限制
  SELECT * INTO v_ip_record
  FROM registration_limits
  WHERE identifier = p_ip_address 
    AND limit_type = 'ip'
    AND last_registration_at > v_window_start;
  
  -- 如果IP被永久封禁
  IF v_ip_record.is_permanently_blocked THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'ip_permanently_blocked',
      'message', '该IP地址已被永久封禁，无法注册'
    );
  END IF;
  
  -- 如果IP被临时封禁
  IF v_ip_record.blocked_until IS NOT NULL AND v_ip_record.blocked_until > now() THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'ip_temporarily_blocked',
      'message', '注册过于频繁，请稍后再试',
      'blocked_until', v_ip_record.blocked_until
    );
  END IF;
  
  -- 检查IP是否超出限制
  IF v_ip_record.registration_count >= p_ip_limit THEN
    -- 封禁24小时
    UPDATE registration_limits
    SET blocked_until = now() + interval '24 hours',
        last_registration_at = now()
    WHERE id = v_ip_record.id;
    
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'ip_limit_exceeded',
      'message', '该IP今日注册次数已达上限，请明天再试'
    );
  END IF;
  
  -- 检查邮箱域名限制
  SELECT * INTO v_domain_record
  FROM registration_limits
  WHERE identifier = v_email_domain 
    AND limit_type = 'email_domain'
    AND last_registration_at > v_window_start;
  
  -- 如果邮箱域名被永久封禁
  IF v_domain_record.is_permanently_blocked THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'domain_permanently_blocked',
      'message', '该邮箱域名已被封禁，无法注册'
    );
  END IF;
  
  -- 检查域名是否超出限制
  IF v_domain_record.registration_count >= p_domain_limit THEN
    -- 封禁24小时
    UPDATE registration_limits
    SET blocked_until = now() + interval '24 hours',
        last_registration_at = now()
    WHERE id = v_domain_record.id;
    
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'domain_limit_exceeded',
      'message', '该邮箱域名今日注册次数已达上限'
    );
  END IF;
  
  -- 更新或插入IP记录
  INSERT INTO registration_limits (identifier, limit_type, registration_count, first_registration_at, last_registration_at)
  VALUES (p_ip_address, 'ip', 1, now(), now())
  ON CONFLICT (identifier, limit_type) 
  DO UPDATE SET 
    registration_count = CASE 
      WHEN registration_limits.last_registration_at <= v_window_start THEN 1
      ELSE registration_limits.registration_count + 1
    END,
    first_registration_at = CASE
      WHEN registration_limits.last_registration_at <= v_window_start THEN now()
      ELSE registration_limits.first_registration_at
    END,
    last_registration_at = now(),
    blocked_until = NULL;
  
  -- 更新或插入域名记录
  INSERT INTO registration_limits (identifier, limit_type, registration_count, first_registration_at, last_registration_at)
  VALUES (v_email_domain, 'email_domain', 1, now(), now())
  ON CONFLICT (identifier, limit_type) 
  DO UPDATE SET 
    registration_count = CASE 
      WHEN registration_limits.last_registration_at <= v_window_start THEN 1
      ELSE registration_limits.registration_count + 1
    END,
    first_registration_at = CASE
      WHEN registration_limits.last_registration_at <= v_window_start THEN now()
      ELSE registration_limits.first_registration_at
    END,
    last_registration_at = now(),
    blocked_until = NULL;
  
  RETURN jsonb_build_object(
    'allowed', true,
    'message', '可以注册'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加唯一约束
ALTER TABLE registration_limits DROP CONSTRAINT IF EXISTS registration_limits_identifier_type_key;
ALTER TABLE registration_limits ADD CONSTRAINT registration_limits_identifier_type_key 
  UNIQUE (identifier, limit_type);

-- 4. 创建管理员封禁/解封函数
CREATE OR REPLACE FUNCTION admin_block_registration(
  p_identifier text,
  p_limit_type text, -- 'ip' or 'email_domain'
  p_permanent boolean DEFAULT false,
  p_admin_id uuid DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_admin_role text;
BEGIN
  -- 检查管理员权限
  IF p_admin_id IS NOT NULL THEN
    SELECT role INTO v_admin_role FROM user_profiles WHERE id = p_admin_id;
    IF v_admin_role NOT IN ('admin', 'super_admin') THEN
      RETURN jsonb_build_object('success', false, 'error', '权限不足');
    END IF;
  END IF;
  
  -- 封禁
  INSERT INTO registration_limits (identifier, limit_type, is_permanently_blocked, blocked_until)
  VALUES (p_identifier, p_limit_type, p_permanent, 
          CASE WHEN p_permanent THEN NULL ELSE now() + interval '30 days' END)
  ON CONFLICT (identifier, limit_type) 
  DO UPDATE SET 
    is_permanently_blocked = p_permanent,
    blocked_until = CASE WHEN p_permanent THEN NULL ELSE now() + interval '30 days' END;
  
  -- 记录日志
  IF p_admin_id IS NOT NULL THEN
    PERFORM log_security_event(
      p_admin_id,
      'registration_blocked',
      NULL,
      NULL,
      jsonb_build_object(
        'identifier', p_identifier,
        'type', p_limit_type,
        'permanent', p_permanent
      ),
      'warning'
    );
  END IF;
  
  RETURN jsonb_build_object('success', true, 'message', '封禁成功');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 解封函数
CREATE OR REPLACE FUNCTION admin_unblock_registration(
  p_identifier text,
  p_limit_type text,
  p_admin_id uuid DEFAULT NULL
) RETURNS jsonb AS $$
BEGIN
  DELETE FROM registration_limits
  WHERE identifier = p_identifier AND limit_type = p_limit_type;
  
  IF p_admin_id IS NOT NULL THEN
    PERFORM log_security_event(
      p_admin_id,
      'registration_unblocked',
      NULL,
      NULL,
      jsonb_build_object('identifier', p_identifier, 'type', p_limit_type),
      'info'
    );
  END IF;
  
  RETURN jsonb_build_object('success', true, 'message', '解封成功');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 创建可疑注册检测函数
CREATE OR REPLACE FUNCTION detect_suspicious_registration(
  p_email text,
  p_ip_address text
) RETURNS jsonb AS $$
DECLARE
  v_is_suspicious boolean := false;
  v_reasons text[] := ARRAY[]::text[];
  v_email_domain text;
BEGIN
  v_email_domain := split_part(p_email, '@', 2);
  
  -- 检测1：一次性邮箱域名
  IF v_email_domain IN (
    'tempmail.com', 'guerrillamail.com', '10minutemail.com', 
    'throwaway.email', 'temp-mail.org', 'mailinator.com'
  ) THEN
    v_is_suspicious := true;
    v_reasons := array_append(v_reasons, 'disposable_email');
  END IF;
  
  -- 检测2：同IP短时间内多次注册
  IF EXISTS (
    SELECT 1 FROM registration_limits
    WHERE identifier = p_ip_address
      AND limit_type = 'ip'
      AND registration_count > 3
      AND last_registration_at > now() - interval '1 hour'
  ) THEN
    v_is_suspicious := true;
    v_reasons := array_append(v_reasons, 'rapid_registration');
  END IF;
  
  -- 检测3：同邮箱域名短时间内大量注册
  IF EXISTS (
    SELECT 1 FROM registration_limits
    WHERE identifier = v_email_domain
      AND limit_type = 'email_domain'
      AND registration_count > 5
      AND last_registration_at > now() - interval '1 hour'
  ) THEN
    v_is_suspicious := true;
    v_reasons := array_append(v_reasons, 'domain_spam');
  END IF;
  
  RETURN jsonb_build_object(
    'is_suspicious', v_is_suspicious,
    'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 更新系统配置
INSERT INTO system_config (key, value, description) VALUES
  ('registration_ip_limit', '5'::jsonb, '每个IP每天最多注册次数'),
  ('registration_domain_limit', '10'::jsonb, '每个邮箱域名每天最多注册次数'),
  ('registration_require_agreement', 'true'::jsonb, '注册是否需要同意协议'),
  ('admin_contact_email', '"news@tournews.top"'::jsonb, '管理员联系邮箱')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 8. RLS策略
ALTER TABLE registration_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（如果有）
DROP POLICY IF EXISTS "admin_view_registration_limits" ON registration_limits;

-- 注意：移除会导致递归的策略
-- registration_limits 通过专用函数访问，避免RLS递归

-- 完成
COMMENT ON TABLE registration_limits IS '注册限制表 - 防止恶意注册';
COMMENT ON FUNCTION check_registration_limit(text, text, int, int) IS '检查注册限制';
COMMENT ON FUNCTION detect_suspicious_registration(text, text) IS '检测可疑注册';
COMMENT ON FUNCTION admin_block_registration(text, text, boolean, uuid) IS '管理员封禁注册';
