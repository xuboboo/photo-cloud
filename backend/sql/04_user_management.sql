-- ============================================
-- 用户管理系统数据库配置
-- ============================================

-- 1. 创建用户配置表（扩展用户信息）
-- ============================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'user', -- 'user', 'admin', 'super_admin'
  is_active boolean NOT NULL DEFAULT true,
  storage_quota bigint NOT NULL DEFAULT 1073741824, -- 1GB 默认配额
  storage_used bigint NOT NULL DEFAULT 0,
  display_name text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON user_profiles(is_active);

-- 启用 RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己的配置
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 用户可以更新自己的配置（但不能修改 role 和 is_active）
CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND
  role = (SELECT role FROM user_profiles WHERE id = auth.uid()) AND
  is_active = (SELECT is_active FROM user_profiles WHERE id = auth.uid())
);

-- 管理员可以查看所有用户配置
CREATE POLICY "Admins can view all profiles"
ON user_profiles FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 管理员可以更新用户配置
CREATE POLICY "Admins can update profiles"
ON user_profiles FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 2. 创建操作日志表
-- ============================================

CREATE TABLE IF NOT EXISTS activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL, -- 'login', 'logout', 'upload', 'delete', 'share', etc.
  resource_type text, -- 'file', 'user', 'profile', etc.
  resource_id uuid,
  details jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);

-- 启用 RLS
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

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
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- 所有认证用户可以插入日志
CREATE POLICY "Authenticated users can insert logs"
ON activity_logs FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 3. 创建文件分享表
-- ============================================

CREATE TABLE IF NOT EXISTS file_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id uuid NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  share_token text UNIQUE NOT NULL,
  password text, -- 可选的分享密码
  expires_at timestamp with time zone,
  max_downloads int, -- 最大下载次数
  download_count int DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_file_shares_file_id ON file_shares(file_id);
CREATE INDEX IF NOT EXISTS idx_file_shares_user_id ON file_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_file_shares_share_token ON file_shares(share_token);
CREATE INDEX IF NOT EXISTS idx_file_shares_expires_at ON file_shares(expires_at);

-- 启用 RLS
ALTER TABLE file_shares ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己创建的分享
CREATE POLICY "Users can view own shares"
ON file_shares FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 用户可以创建分享
CREATE POLICY "Users can create shares"
ON file_shares FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 用户可以更新自己的分享
CREATE POLICY "Users can update own shares"
ON file_shares FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

-- 用户可以删除自己的分享
CREATE POLICY "Users can delete own shares"
ON file_shares FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 公开访问分享（通过 token）
CREATE POLICY "Public can view active shares by token"
ON file_shares FOR SELECT
TO anon
USING (
  is_active = true AND
  (expires_at IS NULL OR expires_at > now()) AND
  (max_downloads IS NULL OR download_count < max_downloads)
);

-- 4. 创建文件夹表
-- ============================================

CREATE TABLE IF NOT EXISTS folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  parent_id uuid REFERENCES folders(id) ON DELETE CASCADE,
  path text NOT NULL, -- 完整路径，如 /folder1/folder2
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_folders_user_id ON folders(user_id);
CREATE INDEX IF NOT EXISTS idx_folders_parent_id ON folders(parent_id);
CREATE INDEX IF NOT EXISTS idx_folders_path ON folders(path);

-- 启用 RLS
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的文件夹
CREATE POLICY "Users can view own folders"
ON folders FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 用户可以创建文件夹
CREATE POLICY "Users can create folders"
ON folders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 用户可以更新自己的文件夹
CREATE POLICY "Users can update own folders"
ON folders FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

-- 用户可以删除自己的文件夹
CREATE POLICY "Users can delete own folders"
ON folders FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 5. 修改 files 表，添加文件夹关联
-- ============================================

ALTER TABLE files ADD COLUMN IF NOT EXISTS folder_id uuid REFERENCES folders(id) ON DELETE SET NULL;
ALTER TABLE files ADD COLUMN IF NOT EXISTS is_public boolean DEFAULT false;
ALTER TABLE files ADD COLUMN IF NOT EXISTS description text;

CREATE INDEX IF NOT EXISTS idx_files_folder_id ON files(folder_id);

-- 6. 创建触发器：自动创建用户配置
-- ============================================

CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_profiles (id, role, is_active)
  VALUES (NEW.id, 'user', true);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();

-- 7. 创建触发器：更新存储使用量
-- ============================================

CREATE OR REPLACE FUNCTION update_storage_used()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE user_profiles
    SET storage_used = storage_used + NEW.size
    WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE user_profiles
    SET storage_used = storage_used - OLD.size
    WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_file_storage_change ON files;
CREATE TRIGGER on_file_storage_change
  AFTER INSERT OR DELETE ON files
  FOR EACH ROW EXECUTE FUNCTION update_storage_used();

-- 8. 创建触发器：更新 updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_folders_updated_at ON folders;
CREATE TRIGGER update_folders_updated_at
  BEFORE UPDATE ON folders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 9. 创建超级管理员函数（仅在首次运行时使用）
-- ============================================

-- 注意：执行此函数需要在注册第一个用户后手动调用
-- 将第一个注册的用户设置为超级管理员
CREATE OR REPLACE FUNCTION set_first_user_as_super_admin()
RETURNS void AS $$
DECLARE
  first_user_id uuid;
BEGIN
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. 创建视图：用户统计
-- ============================================

CREATE OR REPLACE VIEW user_statistics AS
SELECT 
  up.id,
  u.email,
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
GROUP BY up.id, u.email, up.display_name, up.role, up.is_active, 
         up.storage_used, up.storage_quota, up.created_at;

-- ============================================
-- 配置完成！
-- ============================================

-- 验证配置
SELECT 
  'user_profiles' as table_name, 
  COUNT(*) as row_count 
FROM user_profiles
UNION ALL
SELECT 
  'activity_logs' as table_name, 
  COUNT(*) as row_count 
FROM activity_logs
UNION ALL
SELECT 
  'file_shares' as table_name, 
  COUNT(*) as row_count 
FROM file_shares
UNION ALL
SELECT 
  'folders' as table_name, 
  COUNT(*) as row_count 
FROM folders;
