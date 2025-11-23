# 删除用户功能部署说明

## 功能说明

此功能允许超级管理员完全删除用户及其所有关联数据，包括：
- 用户的所有文件（Storage 和数据库记录）
- 用户的所有文件夹
- 用户的所有分享链接
- 用户的活动日志
- 用户配置信息
- 用户认证账户

## 部署步骤

### 1. 部署数据库函数

在 Supabase Dashboard 中执行以下操作：

1. 进入 **SQL Editor**
2. 打开 `12_delete_user_function.sql` 文件
3. 复制所有内容
4. 在 SQL Editor 中粘贴并执行

或者使用 Supabase CLI：

```bash
supabase db push --file backend/sql/12_delete_user_function.sql
```

### 2. 验证部署

执行以下 SQL 查询验证函数是否创建成功：

```sql
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('delete_user_completely', 'get_user_file_paths');
```

应该返回两条记录：
- `delete_user_completely` - FUNCTION
- `get_user_file_paths` - FUNCTION

### 3. 权限说明

- **delete_user_completely**: 仅超级管理员可以调用
- **get_user_file_paths**: 管理员和超级管理员可以调用

函数会自动检查调用者的权限，无权限用户调用会收到错误提示。

## 安全机制

### 1. 权限检查
- 只有超级管理员才能删除用户
- 不能删除自己的账户
- 不能删除其他超级管理员账户

### 2. 二次确认
前端实现了两次确认机制：
1. 第一次：显示将要删除的内容并确认
2. 第二次：要求输入用户邮箱以最终确认

### 3. 完整性保证
使用数据库事务确保删除操作的原子性，要么全部删除成功，要么全部回滚。

## 使用方式

### 前端调用

在管理员页面，超级管理员可以看到删除按钮，点击后：

1. 显示警告信息并确认
2. 要求输入用户邮箱确认
3. 执行删除操作
4. 显示删除结果

### 手动调用（紧急情况）

如果需要在 SQL Editor 中手动删除用户：

```sql
-- 查看用户信息
SELECT id, email, role FROM auth.users WHERE email = 'user@example.com';

-- 删除用户（需要超级管理员权限）
SELECT delete_user_completely('user-uuid-here');
```

## 删除流程

1. **获取文件路径**
   ```sql
   SELECT * FROM get_user_file_paths('user-id');
   ```

2. **删除 Storage 文件**
   - 前端调用 Supabase Storage API 删除文件

3. **删除数据库记录**
   ```sql
   SELECT delete_user_completely('user-id');
   ```
   - 删除文件夹
   - 删除文件记录
   - 删除分享记录
   - 删除活动日志
   - 删除用户配置
   - 删除认证用户

## 返回值

函数返回 JSON 对象：

```json
{
  "success": true,
  "message": "用户已完全删除",
  "statistics": {
    "files_deleted": 10,
    "shares_deleted": 5,
    "folders_deleted": 3,
    "logs_deleted": 100
  }
}
```

如果失败：

```json
{
  "success": false,
  "error": "错误信息"
}
```

## 注意事项

⚠️ **警告**：删除操作不可逆，请谨慎使用！

1. 删除前请确认要删除的用户
2. 建议在执行删除前备份重要数据
3. Storage 中的文件删除失败不会影响数据库记录的删除
4. 如果部分文件删除失败，会在控制台输出错误日志

## 故障排查

### 问题：函数调用失败

**可能原因**：
1. 权限不足（不是超级管理员）
2. 尝试删除自己的账户
3. 尝试删除其他超级管理员

**解决方案**：
- 检查当前用户的 role 字段
- 确认目标用户不是超级管理员
- 确认不是删除自己

### 问题：Storage 文件删除失败

**可能原因**：
1. Storage 权限配置问题
2. 文件路径不正确
3. 文件已被删除

**解决方案**：
- 检查 Storage 的 RLS 策略
- 验证文件路径格式
- 手动清理遗留文件

## 测试建议

在生产环境使用前，建议在测试环境进行以下测试：

1. ✅ 测试删除普通用户
2. ✅ 测试无法删除自己
3. ✅ 测试无法删除超级管理员
4. ✅ 测试普通管理员无法删除用户
5. ✅ 测试删除包含大量文件的用户
6. ✅ 测试 Storage 文件同步删除

## 版本信息

- **版本**: 1.0.0
- **创建日期**: 2024
- **最后更新**: 2024
- **依赖**: Supabase PostgreSQL 14+
