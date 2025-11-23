# ⚡ 新功能快速设置指南

## 🎯 5 分钟完成所有新功能配置

### 第 1 步：执行数据库脚本（2 分钟）

1. 打开 Supabase Dashboard
2. 点击 **SQL Editor**
3. 点击 **New Query**
4. 复制 `backend/sql/04_user_management.sql` 的全部内容
5. 粘贴并点击 **Run**

**预期结果**：
```
Success. No rows returned
```

### 第 2 步：启用邮箱验证（1 分钟）

1. 在 Supabase Dashboard 点击 **Authentication**
2. 点击 **Providers** 标签
3. 点击 **Email** 提供商
4. **勾选** "Confirm email"
5. 点击 **Save**

**注意**：开发环境可以暂时不启用，方便测试。

### 第 3 步：注册测试账户（1 分钟）

1. 刷新浏览器（http://localhost:3000）
2. 注册一个新账户：
   - 邮箱：`admin@example.com`
   - 密码：`admin123456`
3. 如果启用了邮箱验证，去邮箱点击验证链接
4. 登录系统

### 第 4 步：设置超级管理员（1 分钟）

在 Supabase SQL Editor 中执行：

```sql
-- 方法 1：将第一个用户设为超级管理员
SELECT set_first_user_as_super_admin();

-- 或者方法 2：指定邮箱
UPDATE user_profiles
SET role = 'super_admin'
WHERE id = (
  SELECT id FROM auth.users 
  WHERE email = 'admin@example.com'
);
```

### 第 5 步：访问管理后台（30 秒）

1. 刷新浏览器
2. 点击右上角 **"🛡️ 管理后台"** 按钮
3. 查看用户管理界面

---

## ✅ 功能验证清单

### 用户管理
- [ ] 可以看到用户列表
- [ ] 可以修改用户角色
- [ ] 可以启用/禁用用户
- [ ] 可以查看用户统计

### 邮箱验证
- [ ] 注册时收到验证邮件
- [ ] 点击链接后邮箱验证成功
- [ ] 未验证邮箱无法登录

### 存储配额
- [ ] 用户配置中显示配额
- [ ] 上传文件后配额自动更新
- [ ] 超过配额无法上传

### 活动日志
- [ ] 登录操作被记录
- [ ] 上传操作被记录
- [ ] 可以在管理后台查看日志

---

## 🎨 新增的页面和功能

### 1. 管理后台 (`/admin`)

**访问条件**：需要管理员或超级管理员权限

**功能**：
- 👥 用户管理
  - 查看所有用户
  - 修改用户角色
  - 启用/禁用用户
  - 查看用户统计

- 📋 活动日志
  - 查看所有操作记录
  - 按用户筛选
  - 按操作类型筛选

- 📊 系统统计
  - 总用户数
  - 总文件数
  - 总存储使用
  - 总分享数

### 2. 用户配置系统

**自动功能**：
- ✅ 注册时自动创建用户配置
- ✅ 默认 1GB 存储配额
- ✅ 自动计算存储使用量
- ✅ 上传前检查配额

### 3. 文件分享系统（API 已就绪）

**功能**：
- 生成分享链接
- 设置密码保护
- 设置过期时间
- 限制下载次数

**使用示例**：
```javascript
import { createFileShare } from '@/api/shares'

const share = await createFileShare(fileId, {
  password: '123456',
  expiresAt: '2024-12-31',
  maxDownloads: 10
})

console.log('分享链接:', `/share/${share.share_token}`)
```

### 4. 文件夹系统（数据库已就绪）

**功能**：
- 创建文件夹
- 文件夹层级
- 文件归类

---

## 🔐 权限说明

### 角色类型

| 角色 | 权限 |
|------|------|
| **user** | 普通用户，只能管理自己的文件 |
| **admin** | 管理员，可以访问管理后台，管理所有用户 |
| **super_admin** | 超级管理员，拥有所有权限 |

### 权限矩阵

| 功能 | user | admin | super_admin |
|------|------|-------|-------------|
| 上传文件 | ✅ | ✅ | ✅ |
| 删除自己的文件 | ✅ | ✅ | ✅ |
| 创建分享 | ✅ | ✅ | ✅ |
| 访问管理后台 | ❌ | ✅ | ✅ |
| 查看所有用户 | ❌ | ✅ | ✅ |
| 启用/禁用用户 | ❌ | ✅ | ✅ |
| 修改用户角色 | ❌ | ✅ | ✅ |
| 修改超级管理员 | ❌ | ❌ | ✅ |

---

## 📝 常用操作

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

### 查看用户统计

```sql
SELECT * FROM user_statistics;
```

### 查看活动日志

```sql
SELECT 
  u.email,
  al.action,
  al.created_at
FROM activity_logs al
JOIN auth.users u ON u.id = al.user_id
ORDER BY al.created_at DESC
LIMIT 50;
```

---

## 🐛 故障排查

### 问题 1：无法访问管理后台

**检查**：
```sql
-- 查看当前用户角色
SELECT 
  u.email,
  up.role,
  up.is_active
FROM user_profiles up
JOIN auth.users u ON u.id = up.id
WHERE u.email = 'your-email@example.com';
```

**解决**：确保 role 是 'admin' 或 'super_admin'

### 问题 2：用户配置未自动创建

**检查**：
```sql
-- 查看是否有配置
SELECT COUNT(*) FROM user_profiles;
```

**解决**：手动创建
```sql
INSERT INTO user_profiles (id, role, is_active)
SELECT id, 'user', true
FROM auth.users
WHERE id NOT IN (SELECT id FROM user_profiles);
```

### 问题 3：存储配额不更新

**解决**：手动重新计算
```sql
UPDATE user_profiles up
SET storage_used = (
  SELECT COALESCE(SUM(size), 0)
  FROM files
  WHERE user_id = up.id
);
```

### 问题 4：邮箱验证邮件未收到

**检查**：
1. 查看垃圾邮件文件夹
2. 在 Supabase Dashboard → Logs 查看邮件发送日志
3. 确认 Authentication → Email 已启用

---

## 🎉 完成！

现在你的系统拥有：

✅ 完整的用户管理系统  
✅ 邮箱验证功能  
✅ 存储配额管理  
✅ 活动日志记录  
✅ 文件分享系统（API）  
✅ 文件夹组织（数据库）  
✅ 管理后台界面  
✅ 权限控制系统  

**下一步**：
- 测试所有功能
- 根据需要调整配额
- 添加更多管理员
- 开始使用！

---

**需要帮助？** 查看 `NEW_FEATURES_GUIDE.md` 获取详细文档。
