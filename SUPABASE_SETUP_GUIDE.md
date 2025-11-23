# 🚀 Supabase 完整配置教程（2024 最新版）

本教程将手把手教你从零开始配置 Supabase，大约需要 **10-15 分钟**。

---

## 📋 目录

1. [创建 Supabase 账户和项目](#1-创建-supabase-账户和项目)
2. [配置数据库](#2-配置数据库)
3. [配置 Storage 存储](#3-配置-storage-存储)
4. [配置认证系统](#4-配置认证系统)
5. [获取 API 密钥](#5-获取-api-密钥)
6. [配置前端环境变量](#6-配置前端环境变量)
7. [验证配置](#7-验证配置)

---

## 1. 创建 Supabase 账户和项目

### 步骤 1.1：注册账户

1. 访问 **https://supabase.com**
2. 点击右上角 **"Start your project"** 或 **"Sign In"**
3. 选择注册方式：
   - GitHub 账户（推荐，最快）
   - Google 账户
   - 邮箱注册

![注册页面](https://supabase.com/images/login.png)

### 步骤 1.2：创建组织（首次使用）

如果是第一次使用，需要创建组织：

1. 输入组织名称（例如：`My Company`）
2. 选择计划：
   - **Free Plan**（免费，适合开发和小型项目）
   - Pro Plan（付费）
3. 点击 **"Create organization"**

### 步骤 1.3：创建新项目

1. 在 Dashboard 中点击 **"New Project"**
2. 填写项目信息：
   - **Name**（项目名称）：`file-manager`（或任意名称）
   - **Database Password**（数据库密码）：
     - 点击 **"Generate a password"** 自动生成
     - **⚠️ 重要：复制并保存这个密码！**
   - **Region**（区域）：选择离你最近的区域
     - `Southeast Asia (Singapore)` - 新加坡（亚洲用户推荐）
     - `Northeast Asia (Tokyo)` - 东京
     - `East US (North Virginia)` - 美国东部
3. 点击 **"Create new project"**

⏱️ **等待 2-3 分钟**，项目正在初始化...

当看到 **"Project is ready"** 时，说明创建成功！

---

## 2. 配置数据库

### 步骤 2.1：打开 SQL Editor

1. 在左侧菜单中点击 **"SQL Editor"** 图标（看起来像 `</>`）
2. 点击 **"New query"** 按钮

### 步骤 2.2：创建数据库表

1. 复制以下 SQL 代码：

```sql
-- 创建文件表
create table files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  path text not null,
  name text not null,
  type text not null, -- image / markdown
  size int,
  created_at timestamp with time zone default now()
);

-- 创建索引以提升查询性能
create index idx_files_user_id on files(user_id);
create index idx_files_created_at on files(created_at desc);
```

2. 粘贴到 SQL Editor 中
3. 点击右下角 **"Run"** 按钮（或按 `Ctrl+Enter`）
4. 看到 **"Success. No rows returned"** 表示成功！

### 步骤 2.3：配置行级安全策略（RLS）

1. 点击 **"New query"** 创建新查询
2. 复制以下 SQL 代码：

```sql
-- 启用行级安全策略
alter table files enable row level security;

-- 用户只能查看自己的文件
create policy "user_select_own_files" 
on files for select 
to authenticated 
using (auth.uid() = user_id);

-- 用户只能插入自己的文件
create policy "user_insert_own_files" 
on files for insert 
to authenticated 
with check (auth.uid() = user_id);

-- 用户只能删除自己的文件
create policy "user_delete_own_files"
on files for delete
to authenticated
using (auth.uid() = user_id);

-- 用户只能更新自己的文件
create policy "user_update_own_files"
on files for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

3. 点击 **"Run"**
4. 看到 **"Success"** 表示成功！

### 步骤 2.4：验证表创建

1. 在左侧菜单点击 **"Table Editor"**
2. 应该能看到 **"files"** 表
3. 点击表名，可以看到字段结构

✅ **数据库配置完成！**

---

## 3. 配置 Storage 存储

### 步骤 3.1：创建 Storage Bucket

1. 在左侧菜单点击 **"Storage"** 图标
2. 点击 **"Create a new bucket"** 按钮
3. 填写信息：
   - **Name**（名称）：`private-files`
   - **Public bucket**：**取消勾选**（保持私有）
   - **File size limit**：`52428800`（50MB）
4. 点击 **"Create bucket"**

### 步骤 3.2：配置 Storage 策略

1. 点击刚创建的 **"private-files"** bucket
2. 点击顶部的 **"Policies"** 标签
3. 点击 **"New Policy"** 按钮
4. 选择 **"For full customization"**

#### 策略 1：允许用户上传自己的文件

1. 点击 **"Create policy"**
2. 填写：
   - **Policy name**: `Users can upload own files`
   - **Allowed operation**: 勾选 **INSERT**
   - **Target roles**: 选择 **authenticated**
3. 在 **"Policy definition"** 中输入：

```sql
(bucket_id = 'private-files'::text) AND 
((storage.foldername(name))[1] = (auth.uid())::text)
```

4. 点击 **"Review"** → **"Save policy"**

#### 策略 2：允许用户查看自己的文件

1. 再次点击 **"New Policy"** → **"For full customization"**
2. 填写：
   - **Policy name**: `Users can view own files`
   - **Allowed operation**: 勾选 **SELECT**
   - **Target roles**: 选择 **authenticated**
3. **Policy definition**:

```sql
(bucket_id = 'private-files'::text) AND 
((storage.foldername(name))[1] = (auth.uid())::text)
```

4. 点击 **"Review"** → **"Save policy"**

#### 策略 3：允许用户删除自己的文件

1. 再次点击 **"New Policy"** → **"For full customization"**
2. 填写：
   - **Policy name**: `Users can delete own files`
   - **Allowed operation**: 勾选 **DELETE**
   - **Target roles**: 选择 **authenticated**
3. **Policy definition**:

```sql
(bucket_id = 'private-files'::text) AND 
((storage.foldername(name))[1] = (auth.uid())::text)
```

4. 点击 **"Review"** → **"Save policy"**

### 步骤 3.3：验证 Storage 配置

在 **Policies** 标签中，应该能看到 3 个策略：
- ✅ Users can upload own files (INSERT)
- ✅ Users can view own files (SELECT)
- ✅ Users can delete own files (DELETE)

✅ **Storage 配置完成！**

---

## 4. 配置认证系统

### 步骤 4.1：启用邮箱认证

1. 在左侧菜单点击 **"Authentication"** 图标
2. 点击 **"Providers"** 标签
3. 找到 **"Email"** 提供商
4. 确保已启用（应该默认启用）

### 步骤 4.2：配置邮箱验证（可选）

**开发环境建议：关闭邮箱验证**（方便测试）

1. 点击 **"Email"** 提供商进入设置
2. 找到 **"Confirm email"** 选项
3. **取消勾选**（开发时更方便）
4. 点击 **"Save"**

**生产环境建议：开启邮箱验证**（更安全）

### 步骤 4.3：配置站点 URL（重要）

1. 在 Authentication 页面，点击 **"URL Configuration"**
2. 设置：
   - **Site URL**: `http://localhost:3000`（开发环境）
   - **Redirect URLs**: 添加 `http://localhost:3000/**`
3. 点击 **"Save"**

✅ **认证系统配置完成！**

---

## 5. 获取 API 密钥

### 步骤 5.1：打开 API 设置

1. 在左侧菜单点击 **"Settings"** 图标（齿轮）
2. 点击 **"API"** 选项

### 步骤 5.2：复制配置信息

你需要复制两个重要信息：

#### 1. Project URL
- 在 **"Project URL"** 部分
- 格式类似：`https://abcdefghijklmn.supabase.co`
- **复制整个 URL**

#### 2. anon public key
- 在 **"Project API keys"** 部分
- 找到 **"anon public"** 密钥
- 点击右侧的复制图标
- 这是一个很长的字符串，类似：
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDE3NjkyMDAsImV4cCI6MTk1NzM0NTIwMH0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  ```

⚠️ **重要提示**：
- **不要复制** `service_role` 密钥（这是服务端密钥，不安全）
- 只复制 **anon public** 密钥

✅ **API 密钥获取完成！**

---

## 6. 配置前端环境变量

### 步骤 6.1：打开 .env 文件

在你的项目中，打开 `frontend/.env` 文件

### 步骤 6.2：填入配置信息

将文件内容替换为：

```env
# Supabase 配置
VITE_SUPABASE_URL=https://你的项目ID.supabase.co
VITE_SUPABASE_ANON_KEY=你的anon-public-key
```

**示例**（使用你自己的真实值）：

```env
# Supabase 配置
VITE_SUPABASE_URL=https://abcdefghijklmn.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDE3NjkyMDAsImV4cCI6MTk1NzM0NTIwMH0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 步骤 6.3：保存文件

保存 `.env` 文件后，**重启开发服务器**：

```bash
# 如果服务器正在运行，按 Ctrl+C 停止
# 然后重新启动
npm run dev
```

或者直接刷新浏览器页面。

✅ **前端配置完成！**

---

## 7. 验证配置

### 步骤 7.1：检查浏览器控制台

1. 打开浏览器访问 `http://localhost:3000`
2. 按 `F12` 打开开发者工具
3. 查看 **Console** 标签
4. **不应该有红色错误**

### 步骤 7.2：测试注册功能

1. 在登录页面点击 **"还没有账户？立即注册"**
2. 输入测试邮箱和密码：
   - 邮箱：`test@example.com`
   - 密码：`test123456`（至少 6 位）
3. 点击 **"注册"**
4. 如果成功：
   - 显示 "注册成功" 提示
   - 自动切换到登录模式

### 步骤 7.3：测试登录功能

1. 使用刚才注册的账户登录
2. 如果成功：
   - 跳转到主页
   - 显示 "我的文件" 页面
   - 右上角有 "上传文件" 和 "退出登录" 按钮

### 步骤 7.4：测试上传功能

1. 点击 **"上传文件"** 按钮
2. 选择一个图片或创建一个 `.md` 文件
3. 点击 **"上传文件"**
4. 如果成功：
   - 显示 "上传成功" 提示
   - 自动返回主页
   - 文件列表中显示上传的文件

### 步骤 7.5：在 Supabase 中验证

#### 验证数据库

1. 在 Supabase Dashboard 中打开 **"Table Editor"**
2. 点击 **"files"** 表
3. 应该能看到刚才上传的文件记录

#### 验证 Storage

1. 打开 **"Storage"**
2. 点击 **"private-files"** bucket
3. 应该能看到上传的文件（在用户 ID 文件夹中）

✅ **所有配置验证通过！**

---

## 🎉 配置完成！

恭喜你！Supabase 已经完全配置好了。现在你可以：

- ✅ 注册和登录用户
- ✅ 上传文件（图片和 Markdown）
- ✅ 查看文件列表
- ✅ 下载文件
- ✅ 预览 Markdown 文件
- ✅ 删除文件

---

## 🔧 常见问题排查

### 问题 1：注册后无法登录

**原因**：可能启用了邮箱验证

**解决方案**：
1. 进入 Authentication → Providers → Email
2. 取消勾选 "Confirm email"
3. 重新注册

### 问题 2：上传文件失败

**检查清单**：
- [ ] Storage bucket 名称是否为 `private-files`
- [ ] Storage 策略是否正确配置（3 个策略）
- [ ] 文件大小是否超过 50MB
- [ ] 浏览器控制台是否有错误信息

**解决方案**：
1. 检查 Storage → private-files → Policies
2. 确保有 3 个策略且都已启用
3. 重新创建策略（如果有问题）

### 问题 3：无法连接到 Supabase

**检查清单**：
- [ ] `.env` 文件中的 URL 是否正确（包含 `https://`）
- [ ] anon key 是否完整复制
- [ ] 是否重启了开发服务器
- [ ] Supabase 项目是否正常运行

**解决方案**：
1. 重新复制 URL 和 Key
2. 确保没有多余的空格
3. 重启开发服务器：`npm run dev`

### 问题 4：RLS 策略错误

**错误信息**：`new row violates row-level security policy`

**解决方案**：
1. 重新执行 `backend/sql/02_rls.sql`
2. 确保用户已登录
3. 检查策略是否正确配置

### 问题 5：Storage 策略不生效

**解决方案**：
1. 删除现有策略
2. 重新创建策略
3. 确保 Policy definition 中的 SQL 正确
4. 确保 Target roles 选择了 `authenticated`

---

## 📚 下一步

配置完成后，你可以：

1. **阅读开发文档**：`DEVELOPMENT.md`
2. **学习部署**：`DEPLOYMENT.md`
3. **查看项目总览**：`PROJECT_OVERVIEW.md`
4. **开始自定义功能**

---

## 🆘 需要帮助？

如果遇到问题：

1. 查看浏览器控制台错误
2. 查看 Supabase Dashboard 的 Logs
3. 参考 [Supabase 官方文档](https://supabase.com/docs)
4. 提交 Issue

---

## 📝 配置检查清单

完成后确认：

- [ ] Supabase 项目已创建
- [ ] 数据库表已创建（files）
- [ ] RLS 策略已配置（4 个策略）
- [ ] Storage bucket 已创建（private-files）
- [ ] Storage 策略已配置（3 个策略）
- [ ] 邮箱认证已配置
- [ ] API 密钥已获取
- [ ] .env 文件已配置
- [ ] 开发服务器已重启
- [ ] 可以注册/登录
- [ ] 可以上传文件
- [ ] 可以查看文件列表

全部完成？🎉 **开始使用吧！**

---

**最后更新**: 2024-01-01  
**Supabase 版本**: 最新版  
**预计时间**: 10-15 分钟
