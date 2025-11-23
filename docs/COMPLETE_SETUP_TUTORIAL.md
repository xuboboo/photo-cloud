# 🎯 完整配置教程（从零到完成）

## 📋 总览

这个教程将帮你完成：
1. ✅ 基础数据库配置
2. ✅ 用户管理系统配置
3. ✅ 邮箱验证配置
4. ✅ 超级管理员设置
5. ✅ 功能测试

**预计时间**：15-20 分钟

---

## 第一部分：基础配置（如果还没做）

### 步骤 1：配置基础数据库表

1. 打开浏览器，访问 https://supabase.com/dashboard
2. 选择你的项目（azmmtxeeckavivstldxy）
3. 点击左侧菜单的 **SQL Editor** 图标
4. 点击右上角 **New Query** 按钮
5. 复制以下 SQL 代码：

```sql
-- 创建文件表
CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  path text NOT NULL,
  name text NOT NULL,
  type text NOT NULL,
  size int,
  created_at timestamp with time zone DEFAULT now()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_files_user_id ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON files(created_at DESC);

-- 启用 RLS
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "user_select_own_files" ON files;
DROP POLICY IF EXISTS "user_insert_own_files" ON files;
DROP POLICY IF EXISTS "user_delete_own_files" ON files;
DROP POLICY IF EXISTS "user_update_own_files" ON files;

-- 创建新策略
CREATE POLICY "user_select_own_files" 
ON files FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "user_insert_own_files" 
ON files FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_delete_own_files"
ON files FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "user_update_own_files"
ON files FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

6. 点击右下角 **Run** 按钮（或按 Ctrl+Enter）
7. 等待执行完成，应该看到 **"Success. No rows returned"**

✅ **基础表配置完成！**

---

## 第二部分：用户管理系统配置

### 步骤 2：创建用户管理相关表

1. 在 SQL Editor 中，点击 **New Query** 创建新查询
2. 打开项目中的 `backend/sql/04_user_management.sql` 文件
3. **复制全部内容**（大约 400 行）
4. 粘贴到 Supabase SQL Editor
5. 点击 **Run** 执行

**预期结果**：
- 看到 "Success" 消息
- 底部可能显示一个表格，显示各个表的行数（都是 0）

✅ **用户管理系统配置完成！**

---

## 第三部分：Storage 配置（如果还没做）

### 步骤 3：创建 Storage Bucket

1. 在 Supabase Dashboard 点击左侧 **Storage** 图标
2. 查看是否已有 `private-files` bucket
   - **如果有**：跳到步骤 4
   - **如果没有**：继续下面的操作

3. 点击 **Create a new bucket** 按钮
4. 填写信息：
   - **Name**: `private-files`
   - **Public bucket**: **取消勾选**（保持私有）
   - **File size limit**: 留空或填 `52428800`（50MB）
5. 点击 **Create bucket**

### 步骤 4：配置 Storage 策略

1. 点击 `private-files` bucket
2. 点击顶部 **Policies** 标签
3. 查看是否已有策略
   - **如果有 3 个策略**：跳到第四部分
   - **如果没有或不完整**：继续下面的操作

4. 点击 **New Policy** 按钮
5. 选择 **For full customization**

#### 创建策略 1：上传权限

- **Policy name**: `Users can upload own files`
- **Allowed operation**: 勾选 **INSERT**
- **Target roles**: 选择 **authenticated**
- **Policy definition** (WITH CHECK):
```sql
(bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```
- 点击 **Review** → **Save policy**

#### 创建策略 2：查看权限

- 点击 **New Policy** → **For full customization**
- **Policy name**: `Users can view own files`
- **Allowed operation**: 勾选 **SELECT**
- **Target roles**: 选择 **authenticated**
- **Policy definition** (USING):
```sql
(bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```
- 点击 **Review** → **Save policy**

#### 创建策略 3：删除权限

- 点击 **New Policy** → **For full customization**
- **Policy name**: `Users can delete own files`
- **Allowed operation**: 勾选 **DELETE**
- **Target roles**: 选择 **authenticated**
- **Policy definition** (USING):
```sql
(bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
```
- 点击 **Review** → **Save policy**

✅ **Storage 配置完成！**

---

## 第四部分：邮箱验证配置

### 步骤 5：配置邮箱验证（可选）

**开发环境建议**：先关闭邮箱验证，方便测试  
**生产环境建议**：开启邮箱验证，防止恶意注册

#### 关闭邮箱验证（开发环境）

1. 点击左侧 **Authentication** 图标
2. 点击 **Providers** 标签
3. 找到 **Email** 提供商，点击进入
4. **取消勾选** "Confirm email"
5. 点击 **Save**

#### 开启邮箱验证（生产环境）

1. 点击左侧 **Authentication** 图标
2. 点击 **Providers** 标签
3. 找到 **Email** 提供商，点击进入
4. **勾选** "Confirm email"
5. 点击 **Save**

✅ **邮箱验证配置完成！**

---

## 第五部分：注册和设置管理员

### 步骤 6：注册第一个用户

1. 打开浏览器，访问 http://localhost:3000
2. 应该看到登录页面（如果有错误，刷新页面）
3. 点击 **"还没有账户？立即注册"**
4. 输入信息：
   - **邮箱**: `admin@example.com`（或你的真实邮箱）
   - **密码**: `admin123456`（至少 6 位）
5. 点击 **"注册"**

**如果启用了邮箱验证**：
- 去邮箱查收验证邮件
- 点击邮件中的验证链接
- 返回登录页面

**如果关闭了邮箱验证**：
- 应该看到 "注册成功" 提示
- 自动切换到登录模式

### 步骤 7：登录系统

1. 输入刚才注册的邮箱和密码
2. 点击 **"登录"**
3. 应该跳转到主页，显示 "我的文件"

✅ **账户注册完成！**

### 步骤 8：设置超级管理员

1. 回到 Supabase Dashboard
2. 点击 **SQL Editor**
3. 点击 **New Query**
4. 输入以下 SQL：

```sql
-- 方法 1：将第一个注册的用户设为超级管理员
SELECT set_first_user_as_super_admin();
```

或者指定特定邮箱：

```sql
-- 方法 2：指定邮箱（替换为你的邮箱）
UPDATE user_profiles
SET role = 'super_admin'
WHERE id = (
  SELECT id FROM auth.users 
  WHERE email = 'admin@example.com'
);
```

5. 点击 **Run** 执行
6. 应该看到 "Success" 或 "User xxx has been set as super admin"

✅ **超级管理员设置完成！**

---

## 第六部分：验证功能

### 步骤 9：刷新并查看管理后台

1. 回到浏览器（http://localhost:3000）
2. **刷新页面**（F5 或 Ctrl+R）
3. 应该在右上角看到 **"🛡️ 管理后台"** 按钮
4. 点击进入管理后台

**应该看到**：
- 用户管理标签
- 活动日志标签
- 系统统计标签
- 至少有 1 个用户（你自己）

✅ **管理后台可以访问！**

### 步骤 10：测试上传功能

1. 点击左上角返回主页
2. 点击 **"📤 上传文件"**
3. 选择一个图片或创建一个 `.md` 文件
4. 点击 **"上传文件"**
5. 应该看到 "上传成功" 提示
6. 返回主页，文件列表中应该显示刚上传的文件

✅ **上传功能正常！**

### 步骤 11：测试用户管理

1. 注册第二个测试用户：
   - 登出当前账户
   - 注册新账户：`test@example.com` / `test123456`
   - 登录

2. 用管理员账户登录
3. 进入管理后台
4. 应该看到 2 个用户
5. 尝试修改测试用户的角色
6. 尝试禁用/启用测试用户

✅ **用户管理功能正常！**

---

## 🎉 完成！

现在你的系统拥有：

### ✅ 已配置的功能

1. **基础功能**
   - ✅ 用户注册/登录
   - ✅ 文件上传/下载/删除
   - ✅ Markdown 预览

2. **用户管理**
   - ✅ 三级权限系统（普通用户/管理员/超级管理员）
   - ✅ 用户列表查看
   - ✅ 启用/禁用用户
   - ✅ 角色管理

3. **安全功能**
   - ✅ 邮箱验证（可选）
   - ✅ 存储配额限制（默认 1GB）
   - ✅ 行级安全策略
   - ✅ 活动日志记录

4. **管理后台**
   - ✅ 用户管理界面
   - ✅ 活动日志查看
   - ✅ 系统统计面板

---

## 📊 系统状态检查

### 验证数据库表

在 Supabase SQL Editor 中执行：

```sql
-- 查看所有表
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

**应该看到**：
- activity_logs
- file_shares
- files
- folders
- user_profiles

### 验证用户配置

```sql
-- 查看用户列表
SELECT 
  u.email,
  up.role,
  up.is_active,
  up.storage_quota,
  up.storage_used
FROM user_profiles up
JOIN auth.users u ON u.id = up.id;
```

### 验证策略

```sql
-- 查看 files 表的策略
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'files';
```

**应该看到 4 个策略**：
- user_select_own_files (SELECT)
- user_insert_own_files (INSERT)
- user_delete_own_files (DELETE)
- user_update_own_files (UPDATE)

---

## 🔧 常用管理命令

### 添加管理员

```sql
UPDATE user_profiles
SET role = 'admin'
WHERE id = (
  SELECT id FROM auth.users 
  WHERE email = 'user@example.com'
);
```

### 调整用户配额

```sql
-- 设置为 5GB
UPDATE user_profiles
SET storage_quota = 5368709120
WHERE id = (
  SELECT id FROM auth.users 
  WHERE email = 'user@example.com'
);
```

### 禁用用户

```sql
UPDATE user_profiles
SET is_active = false
WHERE id = (
  SELECT id FROM auth.users 
  WHERE email = 'user@example.com'
);
```

### 查看系统统计

```sql
SELECT 
  COUNT(DISTINCT up.id) as total_users,
  COUNT(DISTINCT CASE WHEN up.is_active THEN up.id END) as active_users,
  COUNT(DISTINCT f.id) as total_files,
  SUM(up.storage_used) as total_storage_used
FROM user_profiles up
LEFT JOIN files f ON f.user_id = up.id;
```

---

## 🐛 遇到问题？

### 问题 1：无法访问管理后台

**检查用户角色**：
```sql
SELECT u.email, up.role 
FROM user_profiles up
JOIN auth.users u ON u.id = up.id
WHERE u.email = 'your-email@example.com';
```

**解决**：确保 role 是 'admin' 或 'super_admin'

### 问题 2：上传失败

**检查 Storage bucket**：
1. Storage → private-files
2. 确认 bucket 存在
3. 确认有 3 个策略

### 问题 3：用户配置未创建

**手动创建**：
```sql
INSERT INTO user_profiles (id, role, is_active)
SELECT id, 'user', true
FROM auth.users
WHERE id NOT IN (SELECT id FROM user_profiles);
```

### 问题 4：页面报错

1. 打开浏览器控制台（F12）
2. 查看 Console 标签的错误信息
3. 刷新页面（Ctrl+Shift+R 硬刷新）
4. 清除浏览器缓存

---

## 📚 下一步

现在系统已经完全配置好了，你可以：

1. **添加更多用户**
   - 让团队成员注册
   - 设置他们的角色和配额

2. **自定义配置**
   - 调整默认存储配额
   - 配置邮件模板
   - 自定义界面样式

3. **扩展功能**
   - 实现文件分享界面
   - 添加文件夹管理界面
   - 开发更多管理功能

4. **部署到生产环境**
   - 参考 `DEPLOYMENT.md`
   - 配置自定义域名
   - 启用 HTTPS

---

## 🎓 学习资源

- **项目文档**：
  - `README.md` - 项目介绍
  - `NEW_FEATURES_GUIDE.md` - 新功能详细说明
  - `DEVELOPMENT.md` - 开发指南

- **Supabase 文档**：
  - https://supabase.com/docs
  - https://supabase.com/docs/guides/auth
  - https://supabase.com/docs/guides/storage

---

## ✅ 配置完成检查清单

完成后确认：

- [ ] 基础数据库表已创建（files）
- [ ] 用户管理表已创建（user_profiles, activity_logs, etc.）
- [ ] Storage bucket 已创建（private-files）
- [ ] Storage 策略已配置（3 个）
- [ ] 邮箱验证已配置
- [ ] 第一个用户已注册
- [ ] 超级管理员已设置
- [ ] 可以访问管理后台
- [ ] 可以上传文件
- [ ] 可以管理用户

**全部完成？恭喜你！🎉 系统已经完全就绪！**

---

**需要帮助？**
- 查看 `TROUBLESHOOTING.md`
- 查看浏览器控制台错误
- 查看 Supabase Dashboard 日志
- 提交 Issue

**祝你使用愉快！** 🚀
