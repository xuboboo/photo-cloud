# 🚀 快速启动指南

5 分钟快速启动文件管理系统！

## ⚡ 快速开始

### 第一步：克隆项目

```bash
git clone <your-repo-url>
cd project-root
```

### 第二步：设置 Supabase

1. 访问 [supabase.com](https://supabase.com) 并登录
2. 点击 "New Project" 创建新项目
3. 等待项目初始化完成（约 2 分钟）

### 第三步：配置数据库

在 Supabase Dashboard 中：

1. 点击左侧菜单 "SQL Editor"
2. 点击 "New Query"
3. 复制 `backend/sql/01_tables.sql` 的内容并执行
4. 重复步骤 2-3，执行 `backend/sql/02_rls.sql`

### 第四步：配置 Storage

1. 点击左侧菜单 "Storage"
2. 点击 "Create a new bucket"
3. 名称输入：`private-files`
4. 取消勾选 "Public bucket"（保持私有）
5. 点击 "Create bucket"

### 第五步：配置 Storage 策略

1. 在 Storage 页面，点击 `private-files` bucket
2. 点击 "Policies" 标签
3. 点击 "New Policy"
4. 选择 "For full customization"
5. 复制以下策略并保存：

```sql
-- 用户可以上传自己的文件
create policy "Users can upload own files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'private-files' and 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 用户可以查看自己的文件
create policy "Users can view own files"
on storage.objects for select
to authenticated
using (
  bucket_id = 'private-files' and 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 用户可以删除自己的文件
create policy "Users can delete own files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'private-files' and 
  (storage.foldername(name))[1] = auth.uid()::text
);
```

### 第六步：获取 API 密钥

1. 点击左侧菜单 "Settings" → "API"
2. 复制以下信息：
   - Project URL
   - anon public key

### 第七步：配置前端

```bash
cd frontend

# 安装依赖
npm install

# 创建环境变量文件
cp .env.example .env

# 编辑 .env 文件
# 将第六步复制的信息填入
```

编辑 `frontend/.env`：

```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 第八步：启动应用

```bash
npm run dev
```

浏览器会自动打开 `http://localhost:3000`

## 🎉 完成！

现在你可以：

1. 注册新账户
2. 上传图片和 Markdown 文件
3. 查看文件列表
4. 预览 Markdown 文件
5. 下载文件

## 🔍 验证安装

### 测试注册功能

1. 访问 `http://localhost:3000`
2. 点击"还没有账户？立即注册"
3. 输入邮箱和密码（至少 6 位）
4. 点击"注册"

> 注意：如果 Supabase 启用了邮箱验证，你需要验证邮箱才能登录

### 测试上传功能

1. 登录后点击"上传文件"
2. 选择一个图片或 .md 文件
3. 点击"上传文件"
4. 返回主页查看文件列表

### 测试预览功能

1. 上传一个 Markdown 文件
2. 在文件列表中点击"👁️"图标
3. 查看渲染后的 Markdown

## ❓ 常见问题

### Q: 注册后无法登录？

A: 检查 Supabase 的邮箱验证设置：
1. Settings → Authentication → Email Auth
2. 如果启用了 "Confirm email"，需要验证邮箱
3. 或者暂时禁用邮箱验证进行测试

### Q: 上传文件失败？

A: 检查以下几点：
1. Storage bucket 是否创建成功
2. Storage 策略是否正确配置
3. 浏览器控制台是否有错误信息
4. 文件大小是否超过 50MB

### Q: 无法连接到 Supabase？

A: 检查：
1. `.env` 文件中的 URL 和 Key 是否正确
2. Supabase 项目是否正常运行
3. 网络连接是否正常

### Q: Markdown 预览不显示？

A: 确认：
1. 文件类型是 markdown
2. 文件内容是有效的 Markdown 格式
3. 浏览器控制台是否有错误

## 📚 下一步

- 阅读 [README.md](./README.md) 了解完整功能
- 查看 [DEVELOPMENT.md](./DEVELOPMENT.md) 学习开发指南
- 参考 [DEPLOYMENT.md](./DEPLOYMENT.md) 部署到生产环境

## 🆘 需要帮助？

- 查看 [Supabase 文档](https://supabase.com/docs)
- 查看 [Vue 3 文档](https://vuejs.org/)
- 提交 Issue

## 🎯 快速命令参考

```bash
# 安装依赖
cd frontend && npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 预览生产构建
npm run preview
```

## ✅ 检查清单

安装完成后确认：

- [ ] Supabase 项目已创建
- [ ] 数据库表已创建
- [ ] RLS 策略已配置
- [ ] Storage bucket 已创建
- [ ] Storage 策略已配置
- [ ] 环境变量已配置
- [ ] 依赖已安装
- [ ] 开发服务器已启动
- [ ] 可以注册/登录
- [ ] 可以上传文件
- [ ] 可以查看文件列表
- [ ] 可以预览 Markdown

全部完成？恭喜你！🎉 开始使用吧！
