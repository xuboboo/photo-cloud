# 🔧 故障排查指南

## 当前问题诊断

### ✅ 已修复的问题

1. **TypeError: Cannot read properties of undefined (reading 'user')** ✅
   - 已在所有文件中添加安全检查
   - 使用可选链操作符 `?.`
   - 添加了错误处理

### 🔄 现在请执行

1. **刷新浏览器页面**（按 F5 或 Ctrl+R）
2. 清除浏览器缓存（Ctrl+Shift+Delete）
3. 重新打开 http://localhost:3000

---

## 🚨 常见错误及解决方案

### 错误 1：Cannot read properties of undefined (reading 'user')

**状态**: ✅ 已修复

**如果仍然出现**：
1. 硬刷新浏览器（Ctrl+Shift+R）
2. 清除浏览器缓存
3. 重启开发服务器：
   ```bash
   # 停止服务器（Ctrl+C）
   # 重新启动
   npm run dev
   ```

---

### 错误 2：注册/登录失败

**可能原因**：
- Supabase 配置不正确
- 数据库表未创建
- 邮箱验证未关闭

**解决步骤**：

#### 步骤 1：检查环境变量

打开 `frontend/.env`，确认：
```env
VITE_SUPABASE_URL=https://azmmtxeeckavivstldxy.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

- URL 必须以 `https://` 开头
- Key 必须是完整的长字符串
- 没有多余的空格

#### 步骤 2：检查 Supabase 项目状态

1. 访问 https://supabase.com/dashboard
2. 确认项目状态为 "Active"（绿色）
3. 如果是 "Paused"，点击 "Restore" 恢复

#### 步骤 3：创建数据库表

在 Supabase Dashboard：
1. 点击 **SQL Editor**
2. 点击 **New Query**
3. 执行以下 SQL：

```sql
-- 检查表是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'files';
```

如果返回空结果，说明表未创建，执行：

```sql
-- 创建文件表
create table files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  path text not null,
  name text not null,
  type text not null,
  size int,
  created_at timestamp with time zone default now()
);

-- 创建索引
create index idx_files_user_id on files(user_id);
create index idx_files_created_at on files(created_at desc);

-- 启用 RLS
alter table files enable row level security;

-- 创建策略
create policy "user_select_own_files" on files for select to authenticated using (auth.uid() = user_id);
create policy "user_insert_own_files" on files for insert to authenticated with check (auth.uid() = user_id);
create policy "user_delete_own_files" on files for delete to authenticated using (auth.uid() = user_id);
create policy "user_update_own_files" on files for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

#### 步骤 4：关闭邮箱验证（开发环境）

1. 点击 **Authentication** → **Providers**
2. 点击 **Email**
3. **取消勾选** "Confirm email"
4. 点击 **Save**

---

### 错误 3：上传文件失败

**错误信息**: `new row violates row-level security policy`

**原因**: RLS 策略未配置或用户未登录

**解决方案**：

1. **确认已登录**：
   - 检查右上角是否有 "退出登录" 按钮
   - 如果没有，重新登录

2. **检查 RLS 策略**：
   - 打开 Supabase Dashboard
   - 点击 **Table Editor** → **files**
   - 点击 **Policies** 标签
   - 应该看到 4 个策略（select, insert, delete, update）

3. **重新创建策略**（如果缺失）：
   ```sql
   -- 删除现有策略（如果有）
   drop policy if exists "user_select_own_files" on files;
   drop policy if exists "user_insert_own_files" on files;
   drop policy if exists "user_delete_own_files" on files;
   drop policy if exists "user_update_own_files" on files;
   
   -- 重新创建
   create policy "user_select_own_files" on files for select to authenticated using (auth.uid() = user_id);
   create policy "user_insert_own_files" on files for insert to authenticated with check (auth.uid() = user_id);
   create policy "user_delete_own_files" on files for delete to authenticated using (auth.uid() = user_id);
   create policy "user_update_own_files" on files for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
   ```

---

### 错误 4：Storage 上传失败

**错误信息**: `storage/object-not-found` 或 `Bucket not found`

**原因**: Storage bucket 未创建或策略未配置

**解决方案**：

#### 步骤 1：检查 Bucket

1. 打开 **Storage**
2. 查找名为 `private-files` 的 bucket
3. 如果不存在，创建它：
   - 点击 **Create a new bucket**
   - Name: `private-files`
   - **取消勾选** "Public bucket"
   - 点击 **Create bucket**

#### 步骤 2：配置 Storage 策略

1. 点击 `private-files` bucket
2. 点击 **Policies** 标签
3. 应该有 3 个策略（INSERT, SELECT, DELETE）

如果没有，创建它们：

**策略 1 - 上传**：
- Policy name: `Users can upload own files`
- Allowed operation: **INSERT**
- Target roles: **authenticated**
- Policy definition:
  ```sql
  (bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
  ```

**策略 2 - 查看**：
- Policy name: `Users can view own files`
- Allowed operation: **SELECT**
- Target roles: **authenticated**
- Policy definition:
  ```sql
  (bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
  ```

**策略 3 - 删除**：
- Policy name: `Users can delete own files`
- Allowed operation: **DELETE**
- Target roles: **authenticated**
- Policy definition:
  ```sql
  (bucket_id = 'private-files'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)
  ```

---

### 错误 5：页面空白或无限加载

**可能原因**：
- JavaScript 错误
- 网络问题
- Supabase 连接失败

**诊断步骤**：

1. **打开浏览器控制台**（F12）
2. 查看 **Console** 标签的错误信息
3. 查看 **Network** 标签的请求状态

**常见错误**：

#### 错误：`Failed to fetch`
- 检查网络连接
- 检查 Supabase 项目是否正常运行
- 检查 .env 中的 URL 是否正确

#### 错误：`Invalid API key`
- 检查 .env 中的 ANON_KEY 是否正确
- 重新从 Supabase Dashboard 复制 key
- 确保没有多余的空格或换行

#### 错误：`CORS error`
- 在 Supabase Dashboard 配置 CORS
- Authentication → URL Configuration
- 添加 `http://localhost:3000` 到 Redirect URLs

---

## 🔍 调试技巧

### 1. 查看浏览器控制台

按 **F12** 打开开发者工具：

- **Console** 标签：查看 JavaScript 错误
- **Network** 标签：查看 API 请求
- **Application** 标签：查看 LocalStorage 和 Cookies

### 2. 查看 Supabase 日志

在 Supabase Dashboard：
1. 点击 **Logs**
2. 选择 **API Logs** 或 **Database Logs**
3. 查看最近的错误

### 3. 测试 Supabase 连接

在浏览器控制台执行：

```javascript
// 测试连接
fetch('https://azmmtxeeckavivstldxy.supabase.co/rest/v1/', {
  headers: {
    'apikey': 'your-anon-key',
    'Authorization': 'Bearer your-anon-key'
  }
})
.then(r => r.json())
.then(console.log)
.catch(console.error)
```

如果返回 `{"message":"OK"}`，说明连接正常。

### 4. 检查用户状态

在浏览器控制台执行：

```javascript
// 检查当前用户
const { data } = await window.supabase.auth.getUser()
console.log('Current user:', data)
```

---

## 📋 完整检查清单

在报告问题前，请确认：

### 环境配置
- [ ] Node.js 版本 >= 18
- [ ] npm install 成功执行
- [ ] .env 文件已正确配置
- [ ] 开发服务器正在运行

### Supabase 配置
- [ ] 项目状态为 Active
- [ ] URL 和 Key 正确复制
- [ ] 数据库表已创建（files）
- [ ] RLS 策略已配置（4 个）
- [ ] Storage bucket 已创建（private-files）
- [ ] Storage 策略已配置（3 个）
- [ ] 邮箱验证已关闭（开发环境）

### 浏览器状态
- [ ] 已刷新页面
- [ ] 已清除缓存
- [ ] 控制台无红色错误
- [ ] Network 请求正常

---

## 🆘 仍然有问题？

### 快速重置

如果问题持续，尝试完全重置：

```bash
# 1. 停止开发服务器（Ctrl+C）

# 2. 清除依赖
cd frontend
rm -rf node_modules package-lock.json

# 3. 重新安装
npm install

# 4. 清除浏览器缓存
# 在浏览器中按 Ctrl+Shift+Delete

# 5. 重启服务器
npm run dev
```

### 检查 Supabase 配置

在 SQL Editor 中运行诊断查询：

```sql
-- 检查表
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- 检查策略
SELECT schemaname, tablename, policyname FROM pg_policies WHERE tablename = 'files';

-- 检查用户
SELECT id, email, created_at FROM auth.users;
```

### 获取帮助

提供以下信息：
1. 浏览器控制台的完整错误信息
2. Supabase Dashboard 的日志
3. 你执行的操作步骤
4. 预期结果 vs 实际结果

---

## ✅ 成功标志

系统正常工作时，你应该能够：

1. ✅ 访问 http://localhost:3000 无错误
2. ✅ 看到登录页面
3. ✅ 成功注册新账户
4. ✅ 成功登录
5. ✅ 看到 "我的文件" 页面
6. ✅ 上传文件成功
7. ✅ 查看文件列表
8. ✅ 预览 Markdown 文件
9. ✅ 下载文件
10. ✅ 删除文件
11. ✅ 成功登出

如果以上都能完成，恭喜！系统已经完全正常工作了！🎉

---

**最后更新**: 2024-01-01  
**适用版本**: 1.0.0
