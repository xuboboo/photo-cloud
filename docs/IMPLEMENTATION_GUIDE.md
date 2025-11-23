# 🚀 安全功能实施指南

## 📝 实施步骤

### 第一步：执行SQL脚本

```bash
# 连接到数据库
psql -U postgres -h your-host -d photo_cloud

# 执行安全增强脚本
\i backend/sql/14_security_enhancements.sql

# 验证表创建
\dt rate_limits
\dt security_logs
\dt system_config

# 验证函数创建
\df check_rate_limit
\df check_storage_limit
\df check_share_access
\df admin_set_user_quota
```

### 第二步：验证功能

#### 1. 测试速率限制
```sql
-- 手动测试
SELECT check_rate_limit('test_ip', 'login', 5, 15, 60);
-- 应返回 true

-- 多次调用后
SELECT check_rate_limit('test_ip', 'login', 5, 15, 60);
-- 第6次应返回 false
```

#### 2. 测试存储限制
```sql
-- 查看用户存储统计
SELECT get_user_storage_stats('user-uuid-here');

-- 应返回JSON:
{
  "storage_used": 536870912,
  "storage_quota": 1073741824,
  "storage_percentage": 50.0,
  "file_count": 42,
  "remaining_storage": 536870912,
  "is_full": false,
  "upgrade_contact": "2027911909@qq.com"
}
```

#### 3. 测试管理员配额设置
```sql
-- 管理员设置用户配额为5GB
SELECT admin_set_user_quota(
  'target-user-uuid'::uuid,
  5368709120::bigint,  -- 5GB
  'admin-user-uuid'::uuid
);

-- 应返回成功消息
```

### 第三步：前端集成

#### 1. 在管理后台添加配额管理

在 `Admin.vue` 的用户管理Tab中添加：

```vue
<template>
  <!-- 在用户卡片中添加 -->
  <div class="user-storage-info">
    <div class="storage-usage">
      <span>存储: {{ formatSize(user.storage_used) }} / {{ formatSize(user.storage_quota) }}</span>
      <div class="progress-bar">
        <div 
          class="progress-fill" 
          :style="{ width: calculatePercentage(user) + '%' }"
          :class="{ 'warning': calculatePercentage(user) > 80 }"
        ></div>
      </div>
    </div>
    <button @click="editQuota(user)" v-if="currentUser.role === 'super_admin'">
      调整配额
    </button>
  </div>
</template>

<script>
import { adminSetUserQuota } from '@/api/security'
import { showPrompt } from './dialog-utils' // 使用自定义对话框

async function editQuota(user) {
  const currentGB = (user.storage_quota / 1024 / 1024 / 1024).toFixed(2)
  const newGB = await showPrompt(
    `当前配额：${currentGB} GB\n请输入新配额（GB）：`,
    '调整存储配额',
    currentGB
  )
  
  if (!newGB || isNaN(newGB)) return
  
  try {
    const newQuota = Math.floor(parseFloat(newGB) * 1024 * 1024 * 1024)
    await adminSetUserQuota(user.id, newQuota)
    
    // 刷新用户列表
    await loadUsers()
    
    showSuccess('配额调整成功！')
  } catch (error) {
    showError('配额调整失败：' + error.message)
  }
}

function calculatePercentage(user) {
  return Math.round((user.storage_used / user.storage_quota) * 100)
}

function formatSize(bytes) {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}
</script>

<style scoped>
.user-storage-info {
  margin-top: 10px;
}

.storage-usage {
  font-size: 12px;
  color: #666;
}

.progress-bar {
  height: 4px;
  background: #e0e0e0;
  border-radius: 2px;
  margin: 4px 0;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
  transition: width 0.3s ease;
}

.progress-fill.warning {
  background: linear-gradient(90deg, #f59e0b 0%, #ef4444 100%);
}
</style>
```

#### 2. 创建分享对话框组件

创建 `frontend/src/components/ShareDialog.vue`:

```vue
<template>
  <MobileDialog
    v-model:show="show"
    type="custom"
    title="创建安全分享"
    @confirm="handleCreate"
    @cancel="handleCancel"
  >
    <div class="share-options">
      <!-- 密码保护 -->
      <div class="option-group">
        <label>
          <input type="checkbox" v-model="enablePassword" />
          密码保护
        </label>
        <input 
          v-if="enablePassword"
          v-model="password"
          type="text"
          placeholder="输入分享密码"
          class="password-input"
        />
      </div>

      <!-- 有效期 -->
      <div class="option-group">
        <label>
          <input type="checkbox" v-model="enableExpiry" />
          设置有效期
        </label>
        <select v-if="enableExpiry" v-model="expiryDays">
          <option value="1">1天</option>
          <option value="3">3天</option>
          <option value="7">7天</option>
          <option value="30">30天</option>
        </select>
      </div>

      <!-- 下载次数限制 -->
      <div class="option-group">
        <label>
          <input type="checkbox" v-model="enableDownloadLimit" />
          限制下载次数
        </label>
        <input 
          v-if="enableDownloadLimit"
          v-model.number="maxDownloads"
          type="number"
          min="1"
          max="100"
          placeholder="最大下载次数"
        />
      </div>
    </div>
  </MobileDialog>
</template>

<script setup>
import { ref, computed } from 'vue'
import MobileDialog from './MobileDialog.vue'

const props = defineProps({
  show: Boolean,
  fileId: String
})

const emit = defineEmits(['update:show', 'created'])

const enablePassword = ref(false)
const password = ref('')

const enableExpiry = ref(false)
const expiryDays = ref('7')

const enableDownloadLimit = ref(false)
const maxDownloads = ref(10)

async function handleCreate() {
  const options = {}
  
  if (enablePassword.value && password.value) {
    options.password = password.value
  }
  
  if (enableExpiry.value) {
    const expiryDate = new Date()
    expiryDate.setDate(expiryDate.getDate() + parseInt(expiryDays.value))
    options.expiresAt = expiryDate.toISOString()
  }
  
  if (enableDownloadLimit.value && maxDownloads.value > 0) {
    options.maxDownloads = maxDownloads.value
  }
  
  emit('created', options)
  emit('update:show', false)
}

function handleCancel() {
  emit('update:show', false)
}
</script>

<style scoped>
.share-options {
  padding: 20px;
}

.option-group {
  margin-bottom: 15px;
}

.option-group label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 500;
  margin-bottom: 8px;
}

.option-group input[type="text"],
.option-group input[type="number"],
.option-group select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
}
</style>
```

### 第四步：更新上传逻辑

上传功能已自动集成存储检查，无需额外修改。

### 第五步：配置系统参数

```sql
-- 调整速率限制参数
UPDATE system_config
SET value = '{"max_attempts": 3, "window_minutes": 10, "block_minutes": 120}'::jsonb
WHERE key = 'rate_limit_login';

-- 调整默认存储配额
UPDATE system_config
SET value = '2147483648'::jsonb  -- 2GB
WHERE key = 'default_storage_quota';

-- 设置联系邮箱
UPDATE system_config
SET value = '"2027911909@qq.com"'::jsonb
WHERE key = 'upgrade_contact_email';
```

## 🧪 测试场景

### 测试1：存储限制

```javascript
// 1. 模拟用户存储已满
// 2. 尝试上传文件
// 3. 应该看到错误提示：
"存储空间已满！您已使用 1.00 GB / 1.00 GB。

请联系管理员 2027911909@qq.com 升级存储容量。"

// 4. 管理员调整配额到2GB
await adminSetUserQuota(userId, 2 * 1024 * 1024 * 1024)

// 5. 用户重新尝试上传
// 6. 应该成功上传
```

### 测试2：速率限制

```javascript
// 1. 连续5次输入错误密码
// 2. 第6次应该被拒绝：
"操作过于频繁，请稍后再试"

// 3. 等待60分钟或管理员手动解除封禁
DELETE FROM rate_limits WHERE identifier = 'test_user_ip';

// 4. 可以继续尝试登录
```

### 测试3：安全分享

```javascript
// 1. 创建带密码的分享
const share = await createSecureShare(fileId, {
  password: 'test123',
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  maxDownloads: 5
})

// 2. 访问分享链接
const result = await checkShareAccess(share.share_token)
// 应返回 { success: false, requirePassword: true }

// 3. 输入正确密码
const result2 = await checkShareAccess(share.share_token, 'test123')
// 应返回 { success: true, file_id: '...', remaining_downloads: 4 }

// 4. 下载5次后
// 应返回 { success: false, error: '已达到最大下载次数' }
```

## 📊 监控指标

### 关键指标

```sql
-- 1. 速率限制统计
SELECT 
  action,
  COUNT(*) as blocked_count,
  COUNT(DISTINCT identifier) as unique_ips
FROM rate_limits
WHERE blocked_until > now()
GROUP BY action;

-- 2. 存储使用情况
SELECT 
  AVG(storage_used::float / storage_quota * 100) as avg_usage_pct,
  COUNT(*) FILTER (WHERE storage_used >= storage_quota) as full_users,
  COUNT(*) as total_users
FROM user_profiles;

-- 3. 安全事件统计
SELECT 
  action,
  severity,
  COUNT(*) as event_count
FROM security_logs
WHERE created_at > now() - interval '24 hours'
GROUP BY action, severity
ORDER BY event_count DESC;

-- 4. 分享统计
SELECT 
  COUNT(*) as total_shares,
  COUNT(*) FILTER (WHERE password IS NOT NULL) as password_protected,
  COUNT(*) FILTER (WHERE expires_at IS NOT NULL) as with_expiry,
  COUNT(*) FILTER (WHERE max_downloads IS NOT NULL) as with_limit
FROM file_shares
WHERE is_active = true;
```

## 🔔 告警设置

### 关键告警

```javascript
// 1. 存储使用率告警
async function checkStorageAlerts() {
  const { data: users } = await supabase
    .from('user_profiles')
    .select('*')
    .gt('storage_used', 'storage_quota * 0.9')
  
  if (users.length > 0) {
    sendAlert('存储告警', `${users.length}个用户存储使用超过90%`)
  }
}

// 2. 安全事件告警
async function checkSecurityAlerts() {
  const { data: criticalLogs } = await supabase
    .from('security_logs')
    .select('*')
    .eq('severity', 'critical')
    .gt('created_at', new Date(Date.now() - 60 * 60 * 1000))
  
  if (criticalLogs.length > 0) {
    sendAlert('安全告警', `发现${criticalLogs.length}个严重安全事件`)
  }
}

// 3. 速率限制告警
async function checkRateLimitAlerts() {
  const { data: blockedIps } = await supabase
    .from('rate_limits')
    .select('identifier')
    .gt('blocked_until', new Date())
  
  if (blockedIps.length > 10) {
    sendAlert('速率限制告警', `${blockedIps.length}个IP被封禁`)
  }
}

// 定时检查
setInterval(checkStorageAlerts, 60 * 60 * 1000) // 每小时
setInterval(checkSecurityAlerts, 5 * 60 * 1000) // 每5分钟
setInterval(checkRateLimitAlerts, 15 * 60 * 1000) // 每15分钟
```

## 🎯 完成清单

- [ ] 执行SQL脚本创建表和函数
- [ ] 验证数据库功能正常
- [ ] 更新前端API文件
- [ ] 在Admin.vue添加配额管理界面
- [ ] 创建ShareDialog组件
- [ ] 测试存储限制功能
- [ ] 测试速率限制功能
- [ ] 测试分享安全功能
- [ ] 配置系统参数
- [ ] 设置监控告警
- [ ] 培训管理员使用

## 📞 支持

如有问题，联系：
- 📧 技术支持：2027911909@qq.com
- 💬 QQ：2027911909

## 🎉 完成

完成所有步骤后，系统将具备：
- ✅ 企业级安全防护
- ✅ 智能存储管理
- ✅ 安全分享功能
- ✅ 完整审计日志
- ✅ 实时监控告警

**系统已达到生产环境标准！** 🚀🔐
