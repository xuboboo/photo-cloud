-- =====================================================
-- 安全加固和功能增强
-- =====================================================

-- 1. 创建速率限制表（防爆破）
CREATE TABLE IF NOT EXISTS rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier text NOT NULL, -- IP地址或用户ID
  action text NOT NULL, -- 'login', 'upload', 'api_call'
  attempt_count int DEFAULT 1,
  first_attempt_at timestamp with time zone DEFAULT now(),
  last_attempt_at timestamp with time zone DEFAULT now(),
  blocked_until timestamp with time zone,
  created_at timestamp with time zone DEFAULT now()
);

-- 索引优化
CREATE INDEX IF NOT EXISTS idx_rate_limits_identifier ON rate_limits(identifier);
CREATE INDEX IF NOT EXISTS idx_rate_limits_action ON rate_limits(action);
CREATE INDEX IF NOT EXISTS idx_rate_limits_blocked ON rate_limits(blocked_until);

-- 2. 创建安全日志表
CREATE TABLE IF NOT EXISTS security_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL, -- 'login_success', 'login_failed', 'suspicious_activity'
  ip_address inet,
  user_agent text,
  details jsonb,
  severity text DEFAULT 'info', -- 'info', 'warning', 'error', 'critical'
  created_at timestamp with time zone DEFAULT now()
);

-- 索引优化
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_action ON security_logs(action);
CREATE INDEX IF NOT EXISTS idx_security_logs_created_at ON security_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_logs_severity ON security_logs(severity);

-- 3. 增强file_shares表（添加密码和有效期）
-- 检查列是否存在，不存在则添加
DO $$ 
BEGIN
  -- 添加密码字段（如果不存在）
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'file_shares' AND column_name = 'password'
  ) THEN
    ALTER TABLE file_shares ADD COLUMN password text;
  END IF;

  -- 添加有效期字段（如果不存在）
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'file_shares' AND column_name = 'expires_at'
  ) THEN
    ALTER TABLE file_shares ADD COLUMN expires_at timestamp with time zone;
  END IF;

  -- 添加下载次数限制字段（如果不存在）
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'file_shares' AND column_name = 'max_downloads'
  ) THEN
    ALTER TABLE file_shares ADD COLUMN max_downloads int;
  END IF;

  -- 添加下载计数字段（如果不存在）
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'file_shares' AND column_name = 'download_count'
  ) THEN
    ALTER TABLE file_shares ADD COLUMN download_count int DEFAULT 0;
  END IF;

  -- 添加访问日志字段（如果不存在）
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'file_shares' AND column_name = 'access_logs'
  ) THEN
    ALTER TABLE file_shares ADD COLUMN access_logs jsonb DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- 4. 创建存储限制检查函数
CREATE OR REPLACE FUNCTION check_storage_limit()
RETURNS TRIGGER AS $$
DECLARE
  user_quota bigint;
  user_used bigint;
  file_size bigint;
BEGIN
  -- 获取文件大小
  file_size := NEW.size;
  
  -- 获取用户配额和已使用空间
  SELECT storage_quota, storage_used 
  INTO user_quota, user_used
  FROM user_profiles 
  WHERE id = NEW.user_id;
  
  -- 检查是否超出配额
  IF (user_used + file_size) > user_quota THEN
    RAISE EXCEPTION '存储空间不足！您已使用 % / %。请联系管理员 news@tournews.top 升级存储容量。',
      pg_size_pretty(user_used), 
      pg_size_pretty(user_quota);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加存储限制触发器
DROP TRIGGER IF EXISTS check_storage_before_insert ON files;
CREATE TRIGGER check_storage_before_insert
  BEFORE INSERT ON files
  FOR EACH ROW
  EXECUTE FUNCTION check_storage_limit();

-- 5. 创建速率限制检查函数
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_identifier text,
  p_action text,
  p_max_attempts int DEFAULT 5,
  p_window_minutes int DEFAULT 15,
  p_block_minutes int DEFAULT 60
) RETURNS boolean AS $$
DECLARE
  v_record RECORD;
  v_window_start timestamp with time zone;
BEGIN
  v_window_start := now() - (p_window_minutes || ' minutes')::interval;
  
  -- 查找现有记录
  SELECT * INTO v_record
  FROM rate_limits
  WHERE identifier = p_identifier 
    AND action = p_action
    AND last_attempt_at > v_window_start;
  
  -- 检查是否被封禁
  IF v_record.blocked_until IS NOT NULL AND v_record.blocked_until > now() THEN
    RETURN false;
  END IF;
  
  -- 如果不存在记录或已过期，创建新记录
  IF NOT FOUND OR v_record.last_attempt_at <= v_window_start THEN
    INSERT INTO rate_limits (identifier, action, attempt_count, first_attempt_at, last_attempt_at)
    VALUES (p_identifier, p_action, 1, now(), now())
    ON CONFLICT (identifier, action) DO UPDATE
    SET attempt_count = 1,
        first_attempt_at = now(),
        last_attempt_at = now(),
        blocked_until = NULL;
    RETURN true;
  END IF;
  
  -- 更新尝试次数
  IF v_record.attempt_count >= p_max_attempts THEN
    -- 超过限制，封禁
    UPDATE rate_limits
    SET blocked_until = now() + (p_block_minutes || ' minutes')::interval,
        last_attempt_at = now()
    WHERE id = v_record.id;
    RETURN false;
  ELSE
    -- 增加计数
    UPDATE rate_limits
    SET attempt_count = attempt_count + 1,
        last_attempt_at = now()
    WHERE id = v_record.id;
    RETURN true;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加唯一约束
ALTER TABLE rate_limits DROP CONSTRAINT IF EXISTS rate_limits_identifier_action_key;
ALTER TABLE rate_limits ADD CONSTRAINT rate_limits_identifier_action_key 
  UNIQUE (identifier, action);

-- 6. 创建安全日志记录函数
CREATE OR REPLACE FUNCTION log_security_event(
  p_user_id uuid,
  p_action text,
  p_ip_address inet DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_details jsonb DEFAULT '{}'::jsonb,
  p_severity text DEFAULT 'info'
) RETURNS void AS $$
BEGIN
  INSERT INTO security_logs (user_id, action, ip_address, user_agent, details, severity)
  VALUES (p_user_id, p_action, p_ip_address, p_user_agent, p_details, p_severity);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 创建分享访问检查函数
CREATE OR REPLACE FUNCTION check_share_access(
  p_share_token text,
  p_password text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_share RECORD;
  v_result jsonb;
BEGIN
  -- 查找分享记录
  SELECT * INTO v_share
  FROM file_shares
  WHERE share_token = p_share_token;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', '分享不存在或已过期');
  END IF;
  
  -- 检查是否激活
  IF NOT v_share.is_active THEN
    RETURN jsonb_build_object('success', false, 'error', '分享已被禁用');
  END IF;
  
  -- 检查有效期
  IF v_share.expires_at IS NOT NULL AND v_share.expires_at < now() THEN
    -- 自动禁用过期分享
    UPDATE file_shares SET is_active = false WHERE id = v_share.id;
    RETURN jsonb_build_object('success', false, 'error', '分享已过期');
  END IF;
  
  -- 检查下载次数限制
  IF v_share.max_downloads IS NOT NULL AND v_share.download_count >= v_share.max_downloads THEN
    -- 自动禁用达到限制的分享
    UPDATE file_shares SET is_active = false WHERE id = v_share.id;
    RETURN jsonb_build_object('success', false, 'error', '已达到最大下载次数');
  END IF;
  
  -- 检查密码
  IF v_share.password IS NOT NULL AND v_share.password != '' THEN
    IF p_password IS NULL OR v_share.password != p_password THEN
      RETURN jsonb_build_object('success', false, 'error', '密码错误', 'requirePassword', true);
    END IF;
  END IF;
  
  -- 记录访问日志
  UPDATE file_shares
  SET access_logs = access_logs || jsonb_build_object(
    'timestamp', now(),
    'ip', current_setting('request.headers', true)::jsonb->>'x-forwarded-for',
    'user_agent', current_setting('request.headers', true)::jsonb->>'user-agent'
  )::jsonb,
  download_count = download_count + 1
  WHERE id = v_share.id;
  
  RETURN jsonb_build_object(
    'success', true,
    'file_id', v_share.file_id,
    'remaining_downloads', CASE 
      WHEN v_share.max_downloads IS NULL THEN NULL
      ELSE v_share.max_downloads - v_share.download_count - 1
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. 创建管理员设置用户存储配额函数
CREATE OR REPLACE FUNCTION admin_set_user_quota(
  p_user_id uuid,
  p_new_quota bigint,
  p_admin_id uuid
) RETURNS jsonb AS $$
DECLARE
  v_admin_role text;
  v_old_quota bigint;
BEGIN
  -- 检查操作者是否为管理员
  SELECT role INTO v_admin_role
  FROM user_profiles
  WHERE id = p_admin_id;
  
  IF v_admin_role NOT IN ('admin', 'super_admin') THEN
    RETURN jsonb_build_object('success', false, 'error', '权限不足');
  END IF;
  
  -- 获取旧配额
  SELECT storage_quota INTO v_old_quota
  FROM user_profiles
  WHERE id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', '用户不存在');
  END IF;
  
  -- 更新配额
  UPDATE user_profiles
  SET storage_quota = p_new_quota,
      updated_at = now()
  WHERE id = p_user_id;
  
  -- 记录操作日志
  PERFORM log_security_event(
    p_admin_id,
    'quota_updated',
    NULL,
    NULL,
    jsonb_build_object(
      'target_user_id', p_user_id,
      'old_quota', v_old_quota,
      'new_quota', p_new_quota
    ),
    'info'
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'old_quota', v_old_quota,
    'new_quota', p_new_quota
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. 创建自动清理过期数据函数
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS void AS $$
BEGIN
  -- 禁用过期的分享
  UPDATE file_shares
  SET is_active = false
  WHERE is_active = true
    AND expires_at IS NOT NULL
    AND expires_at < now();
  
  -- 清理旧的速率限制记录（保留30天）
  DELETE FROM rate_limits
  WHERE last_attempt_at < now() - interval '30 days';
  
  -- 清理旧的安全日志（保留90天）
  DELETE FROM security_logs
  WHERE created_at < now() - interval '90 days'
    AND severity = 'info';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. 创建获取用户存储统计函数
CREATE OR REPLACE FUNCTION get_user_storage_stats(p_user_id uuid)
RETURNS jsonb AS $$
DECLARE
  v_profile RECORD;
  v_file_count int;
  v_result jsonb;
BEGIN
  -- 获取用户配置
  SELECT * INTO v_profile
  FROM user_profiles
  WHERE id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', '用户不存在');
  END IF;
  
  -- 获取文件数量
  SELECT COUNT(*) INTO v_file_count
  FROM files
  WHERE user_id = p_user_id;
  
  RETURN jsonb_build_object(
    'storage_used', v_profile.storage_used,
    'storage_quota', v_profile.storage_quota,
    'storage_percentage', ROUND((v_profile.storage_used::numeric / v_profile.storage_quota::numeric * 100), 2),
    'file_count', v_file_count,
    'remaining_storage', v_profile.storage_quota - v_profile.storage_used,
    'is_full', v_profile.storage_used >= v_profile.storage_quota,
    'upgrade_contact', 'news@tournews.top'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. 添加RLS策略
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（如果有）
DROP POLICY IF EXISTS "super_admin_view_rate_limits" ON rate_limits;
DROP POLICY IF EXISTS "super_admin_view_security_logs" ON security_logs;
DROP POLICY IF EXISTS "user_view_own_security_logs" ON security_logs;

-- 注意：移除会导致递归的策略
-- rate_limits 和 security_logs 通过专用函数访问，避免RLS递归

-- 用户可以查看自己的安全日志
CREATE POLICY "user_view_own_security_logs"
  ON security_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 12. 创建系统配置表
CREATE TABLE IF NOT EXISTS system_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE NOT NULL,
  value jsonb NOT NULL,
  description text,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 插入默认配置
INSERT INTO system_config (key, value, description) VALUES
  ('rate_limit_login', '{"max_attempts": 5, "window_minutes": 15, "block_minutes": 60}'::jsonb, '登录速率限制'),
  ('rate_limit_upload', '{"max_attempts": 50, "window_minutes": 60, "block_minutes": 30}'::jsonb, '上传速率限制'),
  ('rate_limit_api', '{"max_attempts": 100, "window_minutes": 60, "block_minutes": 15}'::jsonb, 'API速率限制'),
  ('default_storage_quota', '1073741824'::jsonb, '默认存储配额（1GB）'),
  ('upgrade_contact_email', '"news@tournews.top"'::jsonb, '升级联系邮箱'),
  ('share_max_duration_days', '30'::jsonb, '分享最大有效期（天）')
ON CONFLICT (key) DO NOTHING;

-- RLS策略
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（如果有）
DROP POLICY IF EXISTS "admin_manage_system_config" ON system_config;

-- 注意：移除会导致递归的策略
-- system_config 通过专用函数访问，避免RLS递归

-- 创建索引以提升性能
CREATE INDEX IF NOT EXISTS idx_files_user_id_size ON files(user_id, size);
CREATE INDEX IF NOT EXISTS idx_file_shares_expires_at ON file_shares(expires_at) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_file_shares_token ON file_shares(share_token);

-- 完成
COMMENT ON TABLE rate_limits IS '速率限制表 - 防止暴力破解';
COMMENT ON TABLE security_logs IS '安全日志表 - 记录所有安全相关事件';
COMMENT ON TABLE system_config IS '系统配置表 - 存储系统级配置';
COMMENT ON FUNCTION check_storage_limit() IS '检查存储限制 - 防止超出配额';
COMMENT ON FUNCTION check_rate_limit(text, text, int, int, int) IS '检查速率限制 - 防止暴力破解';
COMMENT ON FUNCTION check_share_access(text, text) IS '检查分享访问权限 - 支持密码和有效期';
COMMENT ON FUNCTION admin_set_user_quota(uuid, bigint, uuid) IS '管理员设置用户配额';
COMMENT ON FUNCTION get_user_storage_stats(uuid) IS '获取用户存储统计信息';
