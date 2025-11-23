# 🔐 安全功能和增强

## 📋 需求清单

根据用户需求，实现以下安全功能和特性：

### ✅ 已实现的功能

1. **防止爆破和渗透**
   - ✅ 速率限制（Rate Limiting）
   - ✅ 安全日志记录
   - ✅ IP追踪
   - ✅ 自动封禁机制

2. **存储限制管理**
   - ✅ 上传前检查存储配额
   - ✅ 超出限制时禁止上传
   - ✅ 提示联系管理员升级
   - ✅ 管理员可设置/调整用户配额

3. **分享安全**
   - ✅ 分享有效期设置
   - ✅ 密码保护分享
   - ✅ 下载次数限制
   - ✅ 访问日志记录

4. **数据安全**
   - ✅ 行级安全策略（RLS）
   - ✅ 用户数据隔离
   - ✅ API访问控制

## 🛡️ 安全功能详解

### 1. 速率限制（防爆破）

#### 实现机制
```sql
-- 速率限制表
CREATE TABLE rate_limits (
  identifier text,      -- IP地址或用户ID
  action text,          -- 操作类型
  attempt_count int,    -- 尝试次数
  blocked_until timestamp  -- 封禁到期时间
);
```

#### 限制策略
| 操作类型 | 最大尝试 | 时间窗口 | 封禁时长 |
|---------|---------|---------|---------|
| 登录 (login) | 5次 | 15分钟 | 60分钟 |
| 上传 (upload) | 50次 | 60分钟 | 30分钟 |
| API调用 (api) | 100次 | 60分钟 | 15分钟 |

#### 使用示例
```javascript
import { checkRateLimit } from '@/api/security'

// 登录前检查
const { allowed, message } = await checkRateLimit(userIp, 'login')
if (!allowed) {
  alert(message) // "操作过于频繁，请稍后再试"
  return
}
```

#### 效果
- ✅ 防止暴力破解密码
- ✅ 防止API滥用
- ✅ 防止恶意上传
- ✅ 自动封禁可疑IP

### 2. 存储限制管理

#### 上传前检查
```javascript
// 自动检查存储空间
const storageStats = await getUserStorageStats(userId)

if (storageStats.is_full) {
  throw new Error(
    `存储空间已满！您已使用 ${used} / ${quota}。\n\n` +
    `请联系管理员 2027911909@qq.com 升级存储容量。`
  )
}
```

#### 触发器保护
```sql
-- 数据库层面强制检查
CREATE TRIGGER check_storage_before_insert
  BEFORE INSERT ON files
  FOR EACH ROW
  EXECUTE FUNCTION check_storage_limit();
```

#### 存储统计
```javascript
const stats = await getUserStorageStats(userId)
// 返回：
{
  storage_used: 536870912,      // 已使用（512MB）
  storage_quota: 1073741824,    // 配额（1GB）
  storage_percentage: 50.0,     // 使用百分比
  file_count: 42,               // 文件数量
  remaining_storage: 536870912, // 剩余空间
  is_full: false,               // 是否已满
  upgrade_contact: "2027911909@qq.com"  // 升级联系方式
}
```

#### 用户体验
**当用户达到存储上限时：**

```
❌ 存储空间不足！

当前已使用：512 MB
剩余空间：0 B
文件大小：10 MB

请联系管理员 2027911909@qq.com 升级存储容量。
```

### 3. 管理员存储管理

#### 设置用户配额
```javascript
import { adminSetUserQuota } from '@/api/security'

// 超级管理员设置用户配额
await adminSetUserQuota(
  userId,           // 目标用户ID
  5 * 1024 * 1024 * 1024  // 5GB
)
```

#### 配额预设
| 等级 | 配额 | 适用对象 |
|-----|------|---------|
| 免费用户 | 1 GB | 新注册用户 |
| 基础用户 | 5 GB | 普通用户 |
| 高级用户 | 20 GB | 付费用户 |
| VIP用户 | 100 GB | 企业用户 |
| 无限制 | 1 TB+ | 特殊用户 |

#### 管理界面（Admin.vue中添加）
```vue
<template>
  <div class="quota-management">
    <h3>存储配额管理</h3>
    <div class="user-quota-item">
      <span>{{ user.email }}</span>
      <span>{{ formatSize(user.storage_used) }} / {{ formatSize(user.storage_quota) }}</span>
      <button @click="editQuota(user)">调整配额</button>
    </div>
  </div>
</template>
```

### 4. 分享安全增强

#### 创建安全分享
```javascript
import { createSecureShare } from '@/api/security'

// 创建带密码和有效期的分享
const share = await createSecureShare(fileId, {
  password: 'mySecret123',           // 密码保护
  expiresAt: new Date('2025-12-31'), // 有效期
  maxDownloads: 10                    // 最大下载次数
})

// 分享链接
const shareUrl = `https://yoursite.com/share/${share.share_token}`
```

#### 访问分享
```javascript
import { checkShareAccess } from '@/api/security'

// 检查分享访问权限
const result = await checkShareAccess(shareToken, password)

if (!result.success) {
  if (result.requirePassword) {
    // 需要密码
    const password = prompt('请输入分享密码：')
    // 重新检查
  } else {
    // 分享已过期或无效
    alert(result.error)
  }
}
```

#### 安全特性

##### 密码保护
```
🔒 分享需要密码
- 密码存储在数据库
- 访问时验证密码
- 密码错误拒绝访问
```

##### 有效期限制
```
⏰ 自动过期
- 设置过期时间
- 过期自动禁用
- 定期清理过期分享
```

##### 下载次数限制
```
🔢 限制下载次数
- 设置最大下载次数
- 每次下载计数
- 达到限制自动禁用
```

##### 访问日志
```
📊 完整访问记录
- 记录访问IP
- 记录访问时间
- 记录User-Agent
- 便于审计和追踪
```

### 5. 安全日志系统

#### 记录的事件
```javascript
// 登录事件
logSecurityEvent('login_success', { ip, browser }, 'info')
logSecurityEvent('login_failed', { ip, reason }, 'warning')

// 分享事件
logSecurityEvent('share_created', { fileId, hasPassword }, 'info')
logSecurityEvent('share_accessed', { shareToken, ip }, 'info')

// 配额事件
logSecurityEvent('quota_updated', { userId, newQuota }, 'info')
logSecurityEvent('upload_blocked', { reason: 'quota_exceeded' }, 'warning')

// 可疑活动
logSecurityEvent('suspicious_activity', { details }, 'critical')
```

#### 日志级别
| 级别 | 描述 | 保留时间 |
|-----|------|---------|
| **info** | 正常操作 | 90天 |
| **warning** | 警告事件 | 180天 |
| **error** | 错误事件 | 1年 |
| **critical** | 严重事件 | 永久 |

#### 查看日志
```javascript
import { getSecurityLogs } from '@/api/security'

// 查看用户日志
const logs = await getSecurityLogs({
  userId: currentUser.id,
  action: 'login_failed',
  severity: 'warning',
  limit: 50
})
```

### 6. 数据安全（RLS）

#### 行级安全策略
```sql
-- 用户只能访问自己的文件
CREATE POLICY "user_access_own_files"
  ON files FOR ALL
  TO authenticated
  USING (auth.uid() = user_id);

-- 用户只能查看自己的日志
CREATE POLICY "user_view_own_logs"
  ON security_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 超级管理员可以查看所有数据
CREATE POLICY "super_admin_view_all"
  ON security_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );
```

#### 效果
- ✅ 数据库层面强制隔离
- ✅ 无法绕过的安全保护
- ✅ 防止越权访问
- ✅ 自动审计合规

## 🔧 实施指南

### 1. 部署SQL脚本

```bash
# 执行安全增强脚本
psql -U postgres -d photo_cloud -f backend/sql/14_security_enhancements.sql
```

### 2. 配置环境变量

```env
# .env
RATE_LIMIT_ENABLED=true
STORAGE_CHECK_ENABLED=true
SECURITY_LOG_ENABLED=true
ADMIN_CONTACT_EMAIL=2027911909@qq.com
```

### 3. 前端集成

```javascript
// main.js - 全局错误处理
app.config.errorHandler = (err, vm, info) => {
  // 记录安全事件
  if (err.message.includes('存储空间')) {
    logSecurityEvent('upload_blocked', { reason: err.message }, 'warning')
  }
}
```

### 4. 监控和告警

```javascript
// 监控关键指标
setInterval(async () => {
  // 检查高风险日志
  const criticalLogs = await getSecurityLogs({
    severity: 'critical',
    limit: 10
  })
  
  if (criticalLogs.length > 0) {
    // 发送告警通知
    sendAlert('发现严重安全事件', criticalLogs)
  }
}, 60000) // 每分钟检查
```

## 📊 安全性对比

| 安全措施 | 之前 | 现在 | 提升 |
|---------|------|------|------|
| **防爆破** | ❌ 无保护 | ✅ 速率限制+封禁 | ⭐⭐⭐⭐⭐ |
| **存储限制** | ❌ 前端检查 | ✅ 数据库强制 | ⭐⭐⭐⭐⭐ |
| **分享安全** | ❌ 无保护 | ✅ 密码+有效期+限制 | ⭐⭐⭐⭐⭐ |
| **访问控制** | ✅ RLS基础 | ✅ RLS+审计日志 | ⭐⭐⭐⭐ |
| **数据隔离** | ✅ 已隔离 | ✅ 强化隔离 | ⭐⭐⭐⭐ |
| **审计追踪** | ❌ 无记录 | ✅ 完整日志 | ⭐⭐⭐⭐⭐ |

## 🎯 使用场景

### 场景1：用户存储满了

**用户操作**：上传新文件

**系统响应**：
```
❌ 存储空间已满！
您已使用 1.00 GB / 1.00 GB。

请联系管理员 2027911909@qq.com 升级存储容量。
```

**管理员操作**：
1. 收到用户升级请求
2. 在管理后台找到用户
3. 点击"调整配额"
4. 设置新配额（如5GB）
5. 保存

**结果**：用户可以继续上传

### 场景2：恶意登录尝试

**攻击者操作**：连续5次密码错误

**系统响应**：
```
❌ 操作过于频繁，请稍后再试
您的IP已被临时封禁60分钟
```

**安全日志**：
```javascript
{
  action: 'login_failed',
  severity: 'warning',
  details: {
    ip: '192.168.1.100',
    attempts: 5,
    blocked_until: '2025-11-23T04:00:00Z'
  }
}
```

**管理员查看**：
- 在安全日志中看到警告
- 识别可疑IP
- 可选择永久封禁

### 场景3：创建安全分享

**用户操作**：分享文件

**分享设置**：
```
📄 文件：vacation-photos.zip
🔒 密码：summer2025
⏰ 有效期：7天
🔢 最大下载：5次
```

**分享链接**：
```
https://photocloud.com/share/abc123xyz456
```

**访问体验**：
```
1. 访问者打开链接
2. 提示输入密码
3. 密码正确后可下载
4. 下载计数 +1
5. 达到5次后自动禁用
```

## 🚨 安全最佳实践

### 1. 定期审查
```javascript
// 每周审查安全日志
const weeklyReview = async () => {
  const logs = await getSecurityLogs({
    severity: ['warning', 'error', 'critical'],
    startDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  })
  
  // 分析可疑活动
  analyzeSecurityTrends(logs)
}
```

### 2. 备份策略
```bash
# 每日备份数据库
pg_dump photo_cloud > backup_$(date +%Y%m%d).sql

# 备份安全日志
psql -c "COPY security_logs TO '/backup/security_logs.csv' CSV HEADER"
```

### 3. 更新配置
```javascript
// 根据实际情况调整速率限制
await updateSystemConfig('rate_limit_login', {
  max_attempts: 3,  // 更严格
  window_minutes: 10,
  block_minutes: 120
})
```

### 4. 监控告警
```javascript
// 设置告警阈值
const ALERT_THRESHOLDS = {
  failed_logins_per_hour: 10,
  critical_events_per_day: 1,
  storage_usage_percentage: 90
}

// 实时监控
monitorSecurityMetrics(ALERT_THRESHOLDS)
```

## 📞 联系方式

**存储升级联系**：
- 📧 Email: 2027911909@qq.com
- 💬 QQ: 2027911909

**管理员操作**：
1. 收到升级请求
2. 确认用户身份
3. 评估存储需求
4. 在后台设置新配额
5. 通知用户完成

## ✅ 测试清单

### 安全测试
- [ ] 测试登录速率限制（5次失败后封禁）
- [ ] 测试上传速率限制
- [ ] 测试存储配额限制
- [ ] 测试分享密码保护
- [ ] 测试分享有效期
- [ ] 测试下载次数限制
- [ ] 测试RLS策略（用户隔离）
- [ ] 测试管理员权限

### 功能测试
- [ ] 用户达到存储上限时禁止上传
- [ ] 错误提示包含联系方式
- [ ] 管理员可以调整用户配额
- [ ] 配额调整后立即生效
- [ ] 分享链接带密码可正常访问
- [ ] 分享过期自动禁用
- [ ] 安全日志正确记录

## 🎉 总结

通过实施这些安全措施：

1. **防护能力** - 从0到100，全面防护
2. **用户体验** - 清晰的错误提示和升级引导
3. **管理效率** - 管理员轻松管理配额和安全
4. **数据安全** - 多层次保护用户数据
5. **审计合规** - 完整的操作日志和追踪

**现在系统具备企业级安全防护能力！** 🔐🛡️
