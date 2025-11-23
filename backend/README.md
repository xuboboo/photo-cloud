# Supabase 后端配置说明

## 📋 设置步骤

### 1. 创建 Supabase 项目
1. 访问 [supabase.com](https://supabase.com)
2. 创建新项目
3. 记录项目的 URL 和 anon key

### 2. 执行 SQL 脚本
在 Supabase Dashboard 的 SQL Editor 中依次执行：

1. `sql/01_tables.sql` - 创建数据库表
2. `sql/02_rls.sql` - 设置行级安全策略
3. `sql/03_seed.sql` - （可选）初始化种子数据

### 3. 配置 Storage
1. 在 Storage 中创建名为 `private-files` 的 bucket
2. 设置为私有（public: false）
3. 配置文件大小限制为 50MB
4. 参考 `storage-rules/private-files.json` 配置权限

### 4. 配置 Storage 策略
在 Storage 的 Policies 中添加以下策略：

```sql
-- 用户可以上传自己的文件
create policy "Users can upload own files"
on storage.objects for insert
to authenticated
with check (bucket_id = 'private-files' and (storage.foldername(name))[1] = auth.uid()::text);

-- 用户可以查看自己的文件
create policy "Users can view own files"
on storage.objects for select
to authenticated
using (bucket_id = 'private-files' and (storage.foldername(name))[1] = auth.uid()::text);

-- 用户可以删除自己的文件
create policy "Users can delete own files"
on storage.objects for delete
to authenticated
using (bucket_id = 'private-files' and (storage.foldername(name))[1] = auth.uid()::text);
```

### 5. 启用认证
在 Authentication 设置中：
- 启用 Email 认证
- 配置邮件模板（可选）
- 设置密码策略

## 🔐 安全特性

- ✅ 行级安全策略（RLS）确保用户只能访问自己的数据
- ✅ 私有 Storage bucket，需要签名 URL 访问
- ✅ 文件路径包含用户 ID，防止路径猜测
- ✅ 文件大小限制（50MB）
- ✅ MIME 类型白名单

## 📝 注意事项

1. 确保在前端配置正确的 Supabase URL 和 anon key
2. 生产环境建议启用 RLS 审计日志
3. 定期备份数据库
4. 监控 Storage 使用量
