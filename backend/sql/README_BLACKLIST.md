# 邮箱黑名单功能使用说明

## 功能概述

邮箱黑名单功能用于防止恶意用户通过多次注册盗刷系统资源。管理员可以将恶意邮箱添加到黑名单，被拉黑的邮箱将无法注册新账户。

## 功能特性

### ✅ 核心功能
- **添加黑名单**: 单个或批量添加邮箱
- **移除黑名单**: 从黑名单中移除邮箱
- **注册拦截**: 自动阻止黑名单邮箱注册
- **统计信息**: 查看黑名单总数、今日新增、本周新增
- **操作记录**: 记录谁在何时添加了黑名单

### 🔒 权限控制
- 只有管理员（admin）和超级管理员（super_admin）可以管理黑名单
- 注册时自动检查，无需权限

## 部署步骤

### 1. 执行SQL脚本

在 Supabase Dashboard 的 SQL Editor 中执行：

```bash
# 打开 SQL Editor
# 复制 backend/sql/13_email_blacklist.sql 的全部内容
# 粘贴并执行
```

或使用 Supabase CLI：

```bash
supabase db push
```

### 2. 验证部署

执行以下查询验证：

```sql
-- 检查表是否创建
SELECT * FROM email_blacklist LIMIT 5;

-- 检查函数是否存在
SELECT routine_name FROM information_schema.routines
WHERE routine_name LIKE '%blacklist%';
```

应该返回以下函数：
- `is_email_blacklisted`
- `add_email_to_blacklist`
- `remove_email_from_blacklist`
- `batch_add_emails_to_blacklist`
- `get_blacklist_stats`
- `check_email_before_signup`

## 使用方式

### 管理员界面操作

#### 1. 进入黑名单管理
1. 登录管理员账户
2. 进入管理后台
3. 点击 "邮箱黑名单" 标签

#### 2. 添加单个邮箱
1. 点击 "➕ 添加邮箱" 按钮
2. 输入要拉黑的邮箱地址
3. 输入拉黑原因（可选）
4. 确认添加

**智能提示**：如果邮箱已有注册用户，系统会询问是否同时删除该用户。

#### 3. 批量添加邮箱
1. 点击 "📋 批量添加" 按钮
2. 输入邮箱列表（每行一个）
   ```
   spam1@example.com
   spam2@example.com
   spam3@example.com
   ```
3. 输入拉黑原因（可选，统一应用）
4. 确认添加

#### 4. 移除黑名单
1. 找到要移除的邮箱
2. 点击 "✖️ 移除" 按钮
3. 确认操作

### 用户注册流程

当用户尝试注册时：

1. **输入邮箱和密码**
2. **自动检查黑名单**（后台进行）
3. **结果判断**：
   - ✅ 不在黑名单：允许注册
   - ❌ 在黑名单中：显示错误信息，阻止注册

```
该邮箱已被禁止注册，如有疑问请联系管理员
```

## API 使用示例

### 前端调用

```javascript
import { 
  getEmailBlacklist, 
  addEmailToBlacklist, 
  removeEmailFromBlacklist,
  checkEmailBeforeSignup 
} from '@/api/admin'

// 获取黑名单列表
const blacklist = await getEmailBlacklist()

// 添加邮箱到黑名单
await addEmailToBlacklist('spam@example.com', '恶意注册')

// 移除黑名单
await removeEmailFromBlacklist('spam@example.com')

// 注册前检查
const result = await checkEmailBeforeSignup('user@example.com')
if (!result.allowed) {
  alert(result.message)
}
```

### 数据库函数调用

```sql
-- 检查邮箱是否在黑名单
SELECT is_email_blacklisted('test@example.com');

-- 添加到黑名单
SELECT add_email_to_blacklist('spam@example.com', '恶意注册');

-- 移除黑名单
SELECT remove_email_from_blacklist('spam@example.com');

-- 批量添加
SELECT batch_add_emails_to_blacklist(
  '["spam1@example.com", "spam2@example.com"]'::jsonb,
  '批量拉黑'
);

-- 获取统计信息
SELECT get_blacklist_stats();
```

## 数据表结构

### email_blacklist 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | uuid | 主键 |
| email | text | 邮箱地址（唯一） |
| reason | text | 拉黑原因 |
| blocked_by | uuid | 操作的管理员ID |
| created_at | timestamp | 添加时间 |
| updated_at | timestamp | 更新时间 |

### blacklist_details 视图

包含黑名单详情及操作人信息：
- 黑名单基本信息
- 操作人邮箱
- 操作人昵称

## 安全机制

### 1. 大小写不敏感
邮箱比较时自动转换为小写，避免大小写绕过。

```sql
-- 以下邮箱被视为相同
spam@example.com
Spam@Example.com
SPAM@EXAMPLE.COM
```

### 2. 权限检查
- 数据库函数级别的权限验证
- RLS 策略保护数据访问
- 前端界面权限控制

### 3. 原子操作
批量添加使用事务，确保数据一致性。

## 常见场景

### 场景1：发现恶意注册

1. 在用户管理中发现可疑用户
2. 点击 "🗑️ 删除" 按钮删除用户
3. 在黑名单管理中添加该邮箱
4. 填写拉黑原因："恶意盗刷"

### 场景2：批量拉黑临时邮箱

收集常见临时邮箱域名列表：
```
spam@temp-mail.com
abuse@10minutemail.com
test@guerrillamail.com
```

使用批量添加功能一次性拉黑。

### 场景3：误拉黑处理

1. 用户反馈无法注册
2. 管理员检查黑名单
3. 确认误拉黑后移除
4. 通知用户重新注册

### 场景4：定期清理

1. 查看黑名单统计
2. 检查过期或无效的邮箱
3. 批量移除不再需要的邮箱

## 监控建议

### 日常监控
- 关注每日新增黑名单数量
- 检查注册失败日志
- 定期审查黑名单合理性

### 告警设置
- 黑名单总数超过阈值
- 单日新增异常多
- 同一邮箱多次尝试注册

## 故障排查

### 问题1：无法添加黑名单

**症状**：点击添加后提示错误

**可能原因**：
- 不是管理员账户
- 邮箱格式不正确
- 邮箱已在黑名单中

**解决方案**：
1. 检查当前用户的 role 字段
2. 验证邮箱格式
3. 查询黑名单确认是否已存在

### 问题2：黑名单邮箱仍能注册

**症状**：拉黑后仍能成功注册

**可能原因**：
- SQL函数未正确部署
- 前端代码未更新
- 浏览器缓存

**解决方案**：
1. 验证函数是否存在
2. 清除浏览器缓存
3. 检查前端调用逻辑

### 问题3：统计信息不准确

**症状**：显示的数量与实际不符

**可能原因**：
- 数据库同步延迟
- 视图未刷新

**解决方案**：
```sql
-- 手动查询验证
SELECT COUNT(*) FROM email_blacklist;

-- 刷新统计
SELECT get_blacklist_stats();
```

## 最佳实践

### ✅ 推荐做法
- 添加黑名单时填写明确的原因
- 定期审查黑名单，移除过期项
- 记录拉黑决策的依据
- 对用户投诉及时响应

### ❌ 避免做法
- 不要随意拉黑正常用户
- 不要批量拉黑常见邮箱域名（如gmail.com）
- 不要忘记告知用户拉黑原因
- 不要长期保留不必要的黑名单

## 性能优化

### 索引优化
系统已创建以下索引：
- `email` 字段索引（快速查询）
- `created_at` 字段索引（时间排序）

### 查询优化
黑名单检查使用数据库函数，性能优化：
- 邮箱比较使用索引
- 函数使用 SECURITY DEFINER 减少权限检查开销

### 缓存建议
考虑在应用层缓存黑名单列表：
- 减少数据库查询
- 提高注册响应速度
- 定期刷新缓存

## 数据备份

定期备份黑名单数据：

```sql
-- 导出黑名单
COPY email_blacklist TO '/tmp/blacklist_backup.csv' CSV HEADER;

-- 导入黑名单
COPY email_blacklist FROM '/tmp/blacklist_backup.csv' CSV HEADER;
```

## 版本历史

- **v1.0.0** (2024) - 初始版本
  - 基础黑名单功能
  - 单个/批量添加
  - 注册拦截
  - 统计信息

## 相关文档

- [用户管理功能](./README_DELETE_USER.md)
- [RLS策略说明](./02_rls.sql)
- [存储配额管理](./07_update_default_quota.sql)

## 技术支持

遇到问题？
1. 查看故障排查部分
2. 检查日志输出
3. 验证数据库函数
4. 联系技术支持
