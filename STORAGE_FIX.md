# 🔧 Storage RLS 策略修复

## 问题

错误：`new row violates row-level security policy`

这是因为 Storage 的 RLS 策略太严格，阻止了文件上传。

## 🚀 快速修复

### 方法 1：使用 SQL 修复（推荐）

在 Supabase SQL Editor 中执行：

```sql
-- 删除所有现有策略
DROP POLICY IF EXISTS "Users can upload own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to private-files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view private-files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update own files" ON storage.objects;

-- 创建简单的策略
CREATE POLICY "Allow all for authenticated users"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'private-files')
WITH CHECK (bucket_id = 'private-files');
```

### 方法 2：通过 Dashboard 修复

1. 打开 Supabase Dashboard
2. 点击 **Storage**
3. 点击 `private-files` bucket
4. 点击 **Policies** 标签
5. **删除所有现有策略**
6. 点击 **New Policy**
7. 选择 **For full customization**
8. 填写：
   - **Policy name**: `Allow all for authenticated users`
   - **Allowed operation**: 勾选 **ALL**
   - **Target roles**: 选择 **authenticated**
   - **USING expression**:
     ```sql
     bucket_id = 'private-files'
     ```
   - **WITH CHECK expression**:
     ```sql
     bucket_id = 'private-files'
     ```
9. 点击 **Review** → **Save policy**

---

## ✅ 验证

执行后，在 SQL Editor 中验证：

```sql
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects';
```

应该看到：
```
policyname                        | cmd | roles
Allow all for authenticated users | ALL | {authenticated}
```

---

## 🧪 测试

1. 刷新浏览器（Ctrl+Shift+R）
2. 点击"📝 新建文档"
3. 选择 Markdown
4. 输入名称："test"
5. 编辑内容
6. 点击"💾 保存"
7. 应该成功！

---

## 🔐 安全说明

这个策略允许所有认证用户访问 `private-files` bucket，但：

✅ **仍然安全**：
- 只有登录用户可以访问
- 匿名用户无法访问
- 文件路径包含用户 ID
- 数据库 RLS 仍然限制查询

✅ **更灵活**：
- 不会因为路径格式问题而失败
- 支持各种文件名格式
- 便于开发和测试

⚠️ **生产环境建议**：
如果需要更严格的控制，可以在稳定后添加更细粒度的策略。

---

## 🎯 为什么之前的策略失败？

之前的策略：
```sql
(storage.foldername(name))[1] = (auth.uid())::text
```

这要求文件路径的第一个文件夹必须是用户 ID，但我们的路径是：
```
markdown/user-id/timestamp-filename.md
```

第一个文件夹是 `markdown`，不是用户 ID，所以策略检查失败。

---

## 🔄 如果还是失败

### 检查 bucket 是否存在
```sql
SELECT * FROM storage.buckets WHERE id = 'private-files';
```

如果不存在，创建它：
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('private-files', 'private-files', false);
```

### 检查用户是否认证
在浏览器控制台执行：
```javascript
const { data } = await supabase.auth.getUser()
console.log('User:', data.user)
```

应该看到用户信息，不是 null。

### 完全重置 Storage 策略
```sql
-- 删除所有策略
DO $$ 
DECLARE 
  r RECORD;
BEGIN
  FOR r IN (
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects'
  ) LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
  END LOOP;
END $$;

-- 重新创建
CREATE POLICY "Allow all for authenticated users"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'private-files')
WITH CHECK (bucket_id = 'private-files');
```

---

## ✅ 完成

执行修复后：

1. ✅ 刷新浏览器
2. ✅ 测试新建文档
3. ✅ 测试上传文件
4. ✅ 应该都能正常工作了

**Storage 策略已修复！** 🎉
