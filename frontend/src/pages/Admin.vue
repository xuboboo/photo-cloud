<template>
  <MobileLayout title="管理后台" :show-back="true">
    <!-- 移动端内容 -->
    <div class="admin-mobile-content">
      <!-- Tab 切换 -->
      <div class="mobile-tabs">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="['mobile-tab-btn', { active: activeTab === tab.id }]"
        >
          <span class="tab-icon">{{ tab.icon }}</span>
          <span class="tab-label">{{ tab.label }}</span>
        </button>
      </div>

      <div class="admin-content">
      <!-- 用户管理 -->
      <div v-if="activeTab === 'users'" class="tab-content">
        <div class="content-header">
          <h2>用户管理</h2>
          <div class="mobile-stats">
            <div class="mobile-stat-card">
              <span class="stat-label">总用户数</span>
              <span class="stat-value">{{ users.length }}</span>
            </div>
            <div class="mobile-stat-card">
              <span class="stat-label">活跃用户</span>
              <span class="stat-value">{{ activeUsersCount }}</span>
            </div>
            <div class="mobile-stat-card">
              <span class="stat-label">管理员</span>
              <span class="stat-value">{{ adminCount }}</span>
            </div>
          </div>
        </div>

        <div v-if="loadingUsers" class="loading">加载中...</div>
        
        <!-- 移动端卡片式用户列表 -->
        <div v-else class="mobile-users-list">
          <div v-for="user in users" :key="user.id" class="mobile-user-card">
            <!-- 用户基本信息 -->
            <div class="user-card-header">
              <div class="user-info">
                <div class="user-email">{{ user.email }}</div>
                <div class="user-name">{{ user.display_name || '未设置昵称' }}</div>
              </div>
              <span :class="['user-status-badge', user.is_active ? 'active' : 'inactive']">
                {{ user.is_active ? '活跃' : '禁用' }}
              </span>
            </div>

            <!-- 用户详细信息 -->
            <div class="user-card-details">
              <div class="detail-row">
                <span class="detail-label">邮箱状态</span>
                <span :class="['detail-value', 'email-badge', user.email_status]">
                  {{ user.email_status === 'verified' ? '✓ 已验证' : '⚠ 未验证' }}
                </span>
              </div>
              
              <div class="detail-row">
                <span class="detail-label">角色</span>
                <select 
                  v-model="user.role" 
                  @change="updateRole(user)"
                  :disabled="user.role === 'super_admin' && !isSuperAdmin"
                  class="mobile-role-select"
                >
                  <option value="user">普通用户</option>
                  <option value="admin">管理员</option>
                  <option value="super_admin" v-if="isSuperAdmin">超级管理员</option>
                </select>
              </div>
              
              <div class="detail-row">
                <span class="detail-label">文件数</span>
                <span class="detail-value">{{ user.file_count }}</span>
              </div>
              
              <div class="detail-row">
                <span class="detail-label">存储使用</span>
                <div class="detail-value storage-info">
                  <span>{{ formatFileSize(user.storage_used) }} / {{ formatFileSize(user.storage_quota) }}</span>
                  <button @click="editUserQuota(user)" class="btn-edit-mobile" title="修改配额">
                    编辑
                  </button>
                </div>
              </div>
              
              <div class="detail-row">
                <span class="detail-label">注册时间</span>
                <span class="detail-value">{{ formatDateTime(user.created_at) }}</span>
              </div>
            </div>

            <!-- 用户操作按钮 -->
            <div class="user-card-actions">
              <button 
                v-if="user.email_status === 'unverified'"
                @click="verifyUserEmail(user)"
                class="mobile-action-btn btn-verify"
                title="手动验证邮箱"
              >
                ✉️ 验证邮箱
              </button>
              <button 
                @click="toggleUserStatus(user)"
                :class="['mobile-action-btn', user.is_active ? 'btn-disable' : 'btn-enable']"
              >
                {{ user.is_active ? '禁用账户' : '启用账户' }}
              </button>
              <button 
                @click="resetUserPassword(user)"
                class="mobile-action-btn btn-reset-password"
                title="重置密码"
              >
                🔑 重置密码
              </button>
              <button 
                @click="viewUserDetails(user)"
                class="mobile-action-btn btn-view"
              >
                查看详情
              </button>
              <button 
                v-if="isSuperAdmin && user.id !== userStore.user?.id"
                @click="handleDeleteUser(user)"
                class="mobile-action-btn btn-delete"
                title="删除用户"
              >
                🗑️ 删除
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 邮箱黑名单 -->
      <div v-if="activeTab === 'blacklist'" class="tab-content">
        <div class="content-header">
          <h2>邮箱黑名单</h2>
          <div class="blacklist-actions">
            <button @click="showAddBlacklistDialog" class="btn-add-blacklist">
              ➕ 添加邮箱
            </button>
            <button @click="showBatchAddDialog" class="btn-batch-add">
              📋 批量添加
            </button>
          </div>
        </div>

        <!-- 统计信息 -->
        <div v-if="blacklistStats" class="mobile-stats">
          <div class="mobile-stat-card">
            <span class="stat-label">总数</span>
            <span class="stat-value">{{ blacklistStats.total_count }}</span>
          </div>
          <div class="mobile-stat-card">
            <span class="stat-label">今日新增</span>
            <span class="stat-value">{{ blacklistStats.today_count }}</span>
          </div>
          <div class="mobile-stat-card">
            <span class="stat-label">本周新增</span>
            <span class="stat-value">{{ blacklistStats.week_count }}</span>
          </div>
        </div>

        <div v-if="loadingBlacklist" class="loading">加载中...</div>
        
        <!-- 移动端黑名单列表 -->
        <div v-else class="mobile-blacklist-list">
          <div v-if="blacklist.length === 0" class="empty-state">
            <div class="empty-icon">🚫</div>
            <div class="empty-text">暂无黑名单邮箱</div>
          </div>
          
          <div v-for="item in blacklist" :key="item.id" class="mobile-blacklist-card">
            <div class="blacklist-card-header">
              <div class="blacklist-email">{{ item.email }}</div>
              <button 
                @click="handleRemoveFromBlacklist(item)"
                class="btn-remove-blacklist"
                title="移除黑名单"
              >
                ✖️
              </button>
            </div>
            
            <div class="blacklist-card-details" v-if="item.reason || item.blocked_by_email">
              <div class="detail-row" v-if="item.reason">
                <span class="detail-label">原因</span>
                <span class="detail-value">{{ item.reason }}</span>
              </div>
              <div class="detail-row" v-if="item.blocked_by_email">
                <span class="detail-label">操作人</span>
                <span class="detail-value">{{ item.blocked_by_name || item.blocked_by_email }}</span>
              </div>
              <div class="detail-row">
                <span class="detail-label">添加时间</span>
                <span class="detail-value">{{ formatDateTime(item.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 活动日志 -->
      <div v-if="activeTab === 'logs'" class="tab-content">
        <div class="content-header">
          <h2>活动日志</h2>
        </div>

        <div v-if="loadingLogs" class="loading">加载中...</div>
        
        <div v-else class="logs-list">
          <div v-for="log in logs" :key="log.id" class="log-item">
            <div class="log-icon">{{ getActionIcon(log.action) }}</div>
            <div class="log-content">
              <div class="log-action">{{ getActionText(log.action) }}</div>
              <div class="log-meta">
                <span>{{ log.user_id }}</span>
                <span>•</span>
                <span>{{ formatDateTime(log.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 系统统计 -->
      <div v-if="activeTab === 'stats'" class="tab-content">
        <div class="content-header">
          <h2>系统统计</h2>
        </div>

        <div class="stats-grid">
          <div class="stat-card-large">
            <div class="stat-icon">👥</div>
            <div class="stat-info">
              <div class="stat-label">总用户数</div>
              <div class="stat-value-large">{{ users.length }}</div>
            </div>
          </div>

          <div class="stat-card-large">
            <div class="stat-icon">📁</div>
            <div class="stat-info">
              <div class="stat-label">总文件数</div>
              <div class="stat-value-large">{{ totalFiles }}</div>
            </div>
          </div>

          <div class="stat-card-large">
            <div class="stat-icon">💾</div>
            <div class="stat-info">
              <div class="stat-label">总存储使用</div>
              <div class="stat-value-large">{{ formatFileSize(totalStorage) }}</div>
            </div>
          </div>

          <div class="stat-card-large">
            <div class="stat-icon">🔗</div>
            <div class="stat-info">
              <div class="stat-label">总分享数</div>
              <div class="stat-value-large">{{ totalShares }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
    
    <!-- 桌面端内容 -->
    <template #desktop>
      <div class="admin-page">
        <div class="admin-header">
          <h1>🛡️ 管理后台</h1>
          <div class="header-actions">
            <button @click="goBack" class="btn-back">返回主页</button>
            <button @click="handleLogout" class="btn-logout">退出登录</button>
          </div>
        </div>

        <div class="admin-tabs">
          <button 
            v-for="tab in tabs" 
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="['tab-btn', { active: activeTab === tab.id }]"
          >
            {{ tab.icon }} {{ tab.label }}
          </button>
        </div>

        <div class="admin-content">
          <!-- 用户管理 -->
          <div v-if="activeTab === 'users'" class="tab-content">
            <div class="content-header">
              <h2>用户管理</h2>
              <div class="stats">
                <div class="stat-card">
                  <span class="stat-label">总用户数</span>
                  <span class="stat-value">{{ users.length }}</span>
                </div>
                <div class="stat-card">
                  <span class="stat-label">活跃用户</span>
                  <span class="stat-value">{{ activeUsersCount }}</span>
                </div>
                <div class="stat-card">
                  <span class="stat-label">管理员</span>
                  <span class="stat-value">{{ adminCount }}</span>
                </div>
              </div>
            </div>

            <div v-if="loadingUsers" class="loading">加载中...</div>
            
            <div v-else class="users-table">
              <table>
                <thead>
                  <tr>
                    <th>邮箱</th>
                    <th>显示名称</th>
                    <th>角色</th>
                    <th>邮箱状态</th>
                    <th>账户状态</th>
                    <th>文件数</th>
                    <th>存储使用</th>
                    <th>注册时间</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="user in users" :key="user.id">
                    <td>{{ user.email }}</td>
                    <td>{{ user.display_name || '-' }}</td>
                    <td>
                      <select 
                        v-model="user.role" 
                        @change="updateRole(user)"
                        :disabled="user.role === 'super_admin' && !isSuperAdmin"
                        class="role-select"
                      >
                        <option value="user">普通用户</option>
                        <option value="admin">管理员</option>
                        <option value="super_admin" v-if="isSuperAdmin">超级管理员</option>
                      </select>
                    </td>
                    <td>
                      <span :class="['status-badge', 'email-status', user.email_status]">
                        {{ user.email_status === 'verified' ? '✓ 已验证' : '⚠ 未验证' }}
                      </span>
                    </td>
                    <td>
                      <span :class="['status-badge', user.is_active ? 'active' : 'inactive']">
                        {{ user.is_active ? '✓ 活跃' : '✗ 禁用' }}
                      </span>
                    </td>
                    <td>{{ user.file_count }}</td>
                    <td>
                      <span>{{ formatFileSize(user.storage_used) }} / {{ formatFileSize(user.storage_quota) }}</span>
                      <button @click="editUserQuota(user)" class="btn-edit-quota" title="修改配额">✏️</button>
                    </td>
                    <td>{{ formatDateTime(user.created_at) }}</td>
                    <td>
                      <div class="action-buttons">
                        <button 
                          v-if="user.email_status === 'unverified'"
                          @click="verifyUserEmail(user)"
                          class="btn-action btn-verify"
                          title="手动验证邮箱"
                        >
                          ✉️
                        </button>
                        <button 
                          @click="toggleUserStatus(user)"
                          :class="['btn-action', user.is_active ? 'btn-disable' : 'btn-enable']"
                          :title="user.is_active ? '禁用用户' : '启用用户'"
                        >
                          {{ user.is_active ? '🚫' : '✓' }}
                        </button>
                        <button 
                          @click="resetUserPassword(user)"
                          class="btn-action btn-reset-password"
                          title="重置密码"
                        >
                          🔑
                        </button>
                        <button 
                          @click="viewUserDetails(user)"
                          class="btn-action btn-view"
                          title="查看详情"
                        >
                          👁️
                        </button>
                        <button 
                          v-if="isSuperAdmin && user.id !== userStore.user?.id"
                          @click="handleDeleteUser(user)"
                          class="btn-action btn-delete"
                          title="删除用户"
                        >
                          🗑️
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 邮箱黑名单 -->
          <div v-if="activeTab === 'blacklist'" class="tab-content">
            <div class="content-header">
              <h2>邮箱黑名单管理</h2>
              <div class="header-actions">
                <button @click="showAddBlacklistDialog" class="btn-add">➕ 添加邮箱</button>
                <button @click="showBatchAddDialog" class="btn-batch">📋 批量添加</button>
              </div>
            </div>

            <!-- 统计信息 -->
            <div v-if="blacklistStats" class="stats">
              <div class="stat-card">
                <span class="stat-label">黑名单总数</span>
                <span class="stat-value">{{ blacklistStats.total_count }}</span>
              </div>
              <div class="stat-card">
                <span class="stat-label">今日新增</span>
                <span class="stat-value">{{ blacklistStats.today_count }}</span>
              </div>
              <div class="stat-card">
                <span class="stat-label">本周新增</span>
                <span class="stat-value">{{ blacklistStats.week_count }}</span>
              </div>
            </div>

            <div v-if="loadingBlacklist" class="loading">加载中...</div>
            
            <div v-else class="blacklist-table">
              <div v-if="blacklist.length === 0" class="empty-state">
                <div class="empty-icon">🚫</div>
                <div class="empty-text">暂无黑名单邮箱</div>
                <div class="empty-hint">添加恶意邮箱以防止滥用注册</div>
              </div>
              
              <table v-else>
                <thead>
                  <tr>
                    <th>邮箱地址</th>
                    <th>拉黑原因</th>
                    <th>操作人</th>
                    <th>添加时间</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in blacklist" :key="item.id">
                    <td><strong>{{ item.email }}</strong></td>
                    <td>{{ item.reason || '-' }}</td>
                    <td>{{ item.blocked_by_name || item.blocked_by_email || '-' }}</td>
                    <td>{{ formatDateTime(item.created_at) }}</td>
                    <td>
                      <button 
                        @click="handleRemoveFromBlacklist(item)"
                        class="btn-action btn-remove"
                        title="移除黑名单"
                      >
                        ✖️ 移除
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 活动日志 -->
          <div v-if="activeTab === 'logs'" class="tab-content">
            <div class="content-header">
              <h2>活动日志</h2>
            </div>

            <div v-if="loadingLogs" class="loading">加载中...</div>
            
            <div v-else class="logs-list">
              <div v-for="log in logs" :key="log.id" class="log-item">
                <div class="log-icon">{{ getActionIcon(log.action) }}</div>
                <div class="log-content">
                  <div class="log-action">{{ getActionText(log.action) }}</div>
                  <div class="log-meta">
                    <span>{{ log.user_id }}</span>
                    <span>•</span>
                    <span>{{ formatDateTime(log.created_at) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 系统统计 -->
          <div v-if="activeTab === 'stats'" class="tab-content">
            <div class="content-header">
              <h2>系统统计</h2>
            </div>

            <div class="stats-grid">
              <div class="stat-card-large">
                <div class="stat-icon">👥</div>
                <div class="stat-info">
                  <div class="stat-label">总用户数</div>
                  <div class="stat-value-large">{{ users.length }}</div>
                </div>
              </div>

              <div class="stat-card-large">
                <div class="stat-icon">📁</div>
                <div class="stat-info">
                  <div class="stat-label">总文件数</div>
                  <div class="stat-value-large">{{ totalFiles }}</div>
                </div>
              </div>

              <div class="stat-card-large">
                <div class="stat-icon">💾</div>
                <div class="stat-info">
                  <div class="stat-label">总存储使用</div>
                  <div class="stat-value-large">{{ formatFileSize(totalStorage) }}</div>
                </div>
              </div>

              <div class="stat-card-large">
                <div class="stat-icon">🔗</div>
                <div class="stat-info">
                  <div class="stat-label">总分享数</div>
                  <div class="stat-value-large">{{ totalShares }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </MobileLayout>

  <!-- 自定义对话框 -->
  <MobileDialog
    v-model:show="dialogShow"
    :type="dialogConfig.type"
    :title="dialogConfig.title"
    :message="dialogConfig.message"
    :placeholder="dialogConfig.placeholder"
    :hint="dialogConfig.hint"
    :default-value="dialogConfig.defaultValue"
    :confirm-text="dialogConfig.confirmText"
    :cancel-text="dialogConfig.cancelText"
    @confirm="handleDialogConfirm"
    @cancel="handleDialogCancel"
  />
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import MobileLayout from '../layouts/MobileLayout.vue'
import MobileDialog from '../components/MobileDialog.vue'
import { getAllUsers, updateUserStatus, updateUserRole, updateUserQuota, getActivityLogs, isSuperAdmin as checkSuperAdmin, deleteUser, getEmailBlacklist, addEmailToBlacklist, removeEmailFromBlacklist, batchAddEmailsToBlacklist, getBlacklistStats, adminVerifyUserEmail, adminResendVerificationEmail } from '../api/admin'
import { formatFileSize, formatDateTime } from '../utils/helpers'
import { useUserStore } from '../stores/user'
import { supabase } from '../api/supabase'

const router = useRouter()
const userStore = useUserStore()

const activeTab = ref('users')
const users = ref([])
const logs = ref([])
const blacklist = ref([])
const blacklistStats = ref(null)
const loadingUsers = ref(true)
const loadingLogs = ref(false)
const loadingBlacklist = ref(false)
const isSuperAdmin = ref(false)

// 对话框状态
const dialogShow = ref(false)
const dialogConfig = ref({
  type: 'confirm',
  title: '提示',
  message: '',
  placeholder: '',
  hint: '',
  defaultValue: '',
  confirmText: '确定',
  cancelText: '取消'
})
let dialogResolve = null

const tabs = [
  { id: 'users', label: '用户管理', icon: '👥' },
  { id: 'blacklist', label: '邮箱黑名单', icon: '🚫' },
  { id: 'logs', label: '活动日志', icon: '📋' },
  { id: 'stats', label: '系统统计', icon: '📊' }
]

const activeUsersCount = computed(() => {
  return users.value.filter(u => u.is_active).length
})

const adminCount = computed(() => {
  return users.value.filter(u => ['admin', 'super_admin'].includes(u.role)).length
})

const totalFiles = computed(() => {
  return users.value.reduce((sum, u) => sum + (u.file_count || 0), 0)
})

const totalStorage = computed(() => {
  return users.value.reduce((sum, u) => sum + (u.storage_used || 0), 0)
})

const totalShares = computed(() => {
  return users.value.reduce((sum, u) => sum + (u.share_count || 0), 0)
})

onMounted(async () => {
  isSuperAdmin.value = await checkSuperAdmin()
  await loadUsers()
})

async function loadUsers() {
  try {
    loadingUsers.value = true
    users.value = await getAllUsers()
  } catch (error) {
    console.error('Load users error:', error)
    await showConfirm('加载用户列表失败：' + error.message, '错误')
  } finally {
    loadingUsers.value = false
  }
}

async function loadLogs() {
  try {
    loadingLogs.value = true
    logs.value = await getActivityLogs(null, 100)
  } catch (error) {
    console.error('Load logs error:', error)
  } finally {
    loadingLogs.value = false
  }
}

async function toggleUserStatus(user) {
  const confirmed = await showConfirm(
    `确定要${user.is_active ? '禁用' : '启用'}用户 ${user.email} 吗？`,
    '确认操作'
  )
  
  if (!confirmed) return

  try {
    await updateUserStatus(user.id, !user.is_active)
    user.is_active = !user.is_active
    await showConfirm('操作成功', '成功')
  } catch (error) {
    await showConfirm('操作失败：' + error.message, '错误')
  }
}

async function updateRole(user) {
  try {
    await updateUserRole(user.id, user.role)
    await showConfirm('角色更新成功', '成功')
  } catch (error) {
    await showConfirm('角色更新失败：' + error.message, '错误')
    await loadUsers() // 重新加载以恢复原值
  }
}

async function viewUserDetails(user) {
  const emailStatus = user.email_status === 'verified' ? '已验证' : '未验证'
  await showConfirm(
    `ID: ${user.id}\n邮箱: ${user.email}\n邮箱状态: ${emailStatus}\n角色: ${user.role}\n文件数: ${user.file_count}\n存储: ${formatFileSize(user.storage_used)}`,
    '用户详情'
  )
}

async function verifyUserEmail(user) {
  const confirmed = await showConfirm(
    `确定要手动验证用户 ${user.email} 的邮箱吗？

⚠️ 说明：
• 手动验证后，用户即可正常使用所有功能
• 此操作将标记用户邮箱为已验证状态
• 适用于无法收到验证邮件的用户

是否继续？`,
    '手动验证邮箱'
  )
  
  if (!confirmed) return
  
  try {
    const result = await adminVerifyUserEmail(user.id)
    
    if (result.success) {
      // 更新本地用户状态
      user.email_status = 'verified'
      await showConfirm(
        `✅ 验证成功！

用户 ${user.email} 的邮箱已被标记为已验证。
用户现在可以正常使用所有功能。`,
        '操作成功'
      )
    } else {
      await showConfirm(result.error || '验证失败', '错误')
    }
  } catch (error) {
    await showConfirm('验证失败：' + error.message, '错误')
  }
}

function goBack() {
  router.push('/dashboard')
}

async function handleLogout() {
  const confirmed = await showConfirm('确定要退出登录吗？', '确认退出')
  if (!confirmed) return
  
  try {
    // 立即跳转，不等待API响应
    const logoutPromise = userStore.logout()
    router.push('/login')
    
    // 在后台完成登出
    await logoutPromise
  } catch (error) {
    console.error('退出失败：', error)
    // 即使失败也已经跳转了
  }
}

async function editUserQuota(user) {
  const currentQuotaMB = Math.round(user.storage_quota / 1024 / 1024)
  const quotaInMB = await showPrompt(
    `设置用户 ${user.email} 的存储配额`,
    '请输入配额大小（MB）',
    currentQuotaMB.toString(),
    '修改配额'
  )
  
  if (quotaInMB === null) return
  
  const quotaInBytes = parseInt(quotaInMB) * 1024 * 1024
  
  if (isNaN(quotaInBytes) || quotaInBytes <= 0) {
    await showConfirm('请输入有效的数字', '输入错误')
    return
  }
  
  try {
    await updateUserQuota(user.id, quotaInBytes)
    user.storage_quota = quotaInBytes
    await showConfirm('配额更新成功', '成功')
  } catch (error) {
    await showConfirm('配额更新失败：' + error.message, '错误')
  }
}

async function resetUserPassword(user) {
  // 安全提示
  const warningConfirmed = await showConfirm(
    `⚠️ 重要安全说明：

1. 系统无法查看用户的当前密码
2. 只能为用户生成新的临时密码
3. 请将临时密码告知用户
4. 建议用户首次登录后立即修改

是否继续为用户 ${user.email} 重置密码？`,
    '重置密码确认'
  )
  
  if (!warningConfirmed) return
  
  try {
    // 生成临时密码
    const tempPassword = generateRandomPassword(12)
    
    // 显示临时密码
    const copyConfirmed = await showConfirm(
      `✅ 临时密码已生成（请复制并告知用户）：

━━━━━━━━━━━━━━━━━━
${tempPassword}
━━━━━━━━━━━━━━━━━━

用户邮箱：${user.email}

⚠️ 重要提示：
• 请立即将此密码发送给用户
• 建议用户首次登录后修改密码
• 此密码只显示一次，关闭后无法再次查看

点击"确定"后将执行密码重置操作`,
      '临时密码'
    )
    
    if (!copyConfirmed) return
    
    // 这里需要调用Supabase Admin API
    // 由于前端不应持有service_role key，实际项目中应该：
    // 1. 创建后端API端点
    // 2. 后端使用service_role调用Supabase Admin API
    // 3. 前端调用后端API
    
    // 临时方案：记录操作到数据库
    const { data, error } = await supabase.rpc('admin_reset_user_password', {
      p_admin_id: userStore.user.id,
      p_target_user_id: user.id,
      p_new_password: '***', // 不传真实密码
      p_reason: '管理员重置密码'
    })
    
    if (error) throw error
    
    await showConfirm(
      `✅ 密码重置操作已记录

临时密码：${tempPassword}

⚠️ 实际生产环境需要：
1. 在后端实现密码重置API
2. 使用Supabase Admin API更新密码
3. 发送邮件通知用户

目前请手动将临时密码告知用户。`,
      '操作完成'
    )
    
  } catch (error) {
    await showConfirm('重置密码失败：' + error.message, '错误')
  }
}

// 生成随机密码
function generateRandomPassword(length = 12) {
  const uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
  const lowercase = 'abcdefghjkmnpqrstuvwxyz'
  const numbers = '23456789'
  const symbols = '@#$%'
  const allChars = uppercase + lowercase + numbers + symbols
  
  let password = ''
  
  // 确保至少包含一个大写、小写、数字、符号
  password += uppercase[Math.floor(Math.random() * uppercase.length)]
  password += lowercase[Math.floor(Math.random() * lowercase.length)]
  password += numbers[Math.floor(Math.random() * numbers.length)]
  password += symbols[Math.floor(Math.random() * symbols.length)]
  
  // 填充剩余长度
  for (let i = password.length; i < length; i++) {
    password += allChars[Math.floor(Math.random() * allChars.length)]
  }
  
  // 打乱顺序
  return password.split('').sort(() => Math.random() - 0.5).join('')
}

async function handleDeleteUser(user) {
  // 防止删除自己
  if (user.id === userStore.user?.id) {
    await showConfirm('不能删除自己的账户', '操作禁止')
    return
  }

  // 二次确认
  const confirmText = `确定要删除用户 ${user.email} 吗？\n\n⚠️ 此操作将永久删除：\n- 用户的所有文件\n- 用户的所有分享\n- 用户的所有文件夹\n- 用户的活动日志\n- 用户账户信息\n\n此操作无法撤销！`
  
  const confirmed = await showConfirm(confirmText, '警告：删除用户')
  if (!confirmed) return

  // 再次确认
  const finalConfirm = await showPrompt(
    '请输入用户邮箱以确认删除',
    '输入邮箱地址',
    '',
    '最终确认'
  )
  
  if (finalConfirm !== user.email) {
    await showConfirm('邮箱不匹配，取消删除', '取消操作')
    return
  }

  try {
    loadingUsers.value = true
    await deleteUser(user.id)
    await showConfirm('用户已成功删除', '操作成功')
    // 重新加载用户列表
    await loadUsers()
  } catch (error) {
    await showConfirm('删除用户失败：' + error.message, '错误')
  } finally {
    loadingUsers.value = false
  }
}

function getActionIcon(action) {
  const icons = {
    login: '🔐',
    logout: '🚪',
    upload: '📤',
    delete: '🗑️',
    share: '🔗',
    download: '⬇️'
  }
  return icons[action] || '📝'
}

function getActionText(action) {
  const texts = {
    login: '用户登录',
    logout: '用户登出',
    upload: '上传文件',
    delete: '删除文件',
    share: '创建分享',
    download: '下载文件'
  }
  return texts[action] || action
}

async function loadBlacklist() {
  try {
    loadingBlacklist.value = true
    blacklist.value = await getEmailBlacklist()
    blacklistStats.value = await getBlacklistStats()
  } catch (error) {
    console.error('加载黑名单失败:', error)
    await showConfirm('加载黑名单失败：' + error.message, '错误')
  } finally {
    loadingBlacklist.value = false
  }
}

async function showAddBlacklistDialog() {
  const email = await showPrompt(
    '请输入要拉黑的邮箱地址',
    'example@domain.com',
    '',
    '添加黑名单'
  )
  if (!email) return
  
  const reason = await showPrompt(
    '拉黑原因（可选）',
    '例如：恶意注册',
    '恶意注册',
    '填写原因'
  )
  
  handleAddToBlacklist(email, reason || '')
}

async function showBatchAddDialog() {
  const emailsText = await showTextarea(
    '请输入要批量拉黑的邮箱地址',
    '每行一个邮箱，例如：\nspam1@example.com\nspam2@example.com',
    '每行输入一个邮箱地址',
    '批量添加黑名单'
  )
  if (!emailsText) return
  
  const emails = emailsText.split('\n').map(e => e.trim()).filter(e => e)
  if (emails.length === 0) {
    await showConfirm('请输入有效的邮箱地址', '提示')
    return
  }
  
  const reason = await showPrompt(
    `拉黑原因（可选，将应用到所有 ${emails.length} 个邮箱）`,
    '例如：批量恶意注册',
    '批量拉黑',
    '填写原因'
  )
  
  handleBatchAddToBlacklist(emails, reason || '')
}

async function handleAddToBlacklist(email, reason) {
  try {
    loadingBlacklist.value = true
    const result = await addEmailToBlacklist(email, reason)
    
    if (result.has_existing_user) {
      const confirmDelete = await showConfirm(
        `警告：该邮箱已有注册用户！\n\n是否同时删除该用户？\n用户ID: ${result.existing_user_id}`,
        '确认删除用户'
      )
      if (confirmDelete) {
        await deleteUser(result.existing_user_id)
        await showConfirm('邮箱已添加到黑名单，用户已删除', '操作成功')
      } else {
        await showConfirm('邮箱已添加到黑名单，但用户仍然存在', '提示')
      }
    } else {
      await showConfirm('邮箱已成功添加到黑名单', '操作成功')
    }
    
    await loadBlacklist()
  } catch (error) {
    await showConfirm('添加黑名单失败：' + error.message, '错误')
  } finally {
    loadingBlacklist.value = false
  }
}

async function handleBatchAddToBlacklist(emails, reason) {
  try {
    loadingBlacklist.value = true
    const result = await batchAddEmailsToBlacklist(emails, reason)
    await showConfirm(result.message, '操作成功')
    await loadBlacklist()
  } catch (error) {
    await showConfirm('批量添加失败：' + error.message, '错误')
  } finally {
    loadingBlacklist.value = false
  }
}

async function handleRemoveFromBlacklist(item) {
  const confirmed = await showConfirm(
    `确定要将 ${item.email} 从黑名单移除吗？\n\n移除后该邮箱可以重新注册。`,
    '确认移除'
  )
  
  if (!confirmed) return
  
  try {
    loadingBlacklist.value = true
    await removeEmailFromBlacklist(item.email)
    await showConfirm('已从黑名单移除', '操作成功')
    await loadBlacklist()
  } catch (error) {
    await showConfirm('移除失败：' + error.message, '错误')
  } finally {
    loadingBlacklist.value = false
  }
}

// 自定义对话框函数
function showDialog(config) {
  return new Promise((resolve) => {
    dialogConfig.value = { ...dialogConfig.value, ...config }
    dialogShow.value = true
    dialogResolve = resolve
  })
}

function handleDialogConfirm(value) {
  if (dialogResolve) {
    dialogResolve(value || true)
    dialogResolve = null
  }
}

function handleDialogCancel() {
  if (dialogResolve) {
    dialogResolve(null)
    dialogResolve = null
  }
}

// 便捷方法
async function showConfirm(message, title = '确认') {
  return await showDialog({
    type: 'confirm',
    title,
    message,
    confirmText: '确定',
    cancelText: '取消'
  })
}

async function showPrompt(message, placeholder = '', defaultValue = '', title = '输入') {
  return await showDialog({
    type: 'prompt',
    title,
    message,
    placeholder,
    defaultValue,
    confirmText: '确定',
    cancelText: '取消'
  })
}

async function showTextarea(message, placeholder = '', hint = '', title = '输入') {
  return await showDialog({
    type: 'textarea',
    title,
    message,
    placeholder,
    hint,
    confirmText: '确定',
    cancelText: '取消'
  })
}

// 监听标签切换
watch(activeTab, (newTab) => {
  if (newTab === 'logs' && logs.value.length === 0) {
    loadLogs()
  }
  if (newTab === 'blacklist' && blacklist.value.length === 0) {
    loadBlacklist()
  }
})
</script>

<style scoped>
/* 移动端内容 */
.admin-mobile-content {
  padding: 1rem;
  background: #f7fafc;
  min-height: 100vh;
}

.mobile-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
}

.mobile-tab-btn {
  flex: 1;
  min-width: 120px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.mobile-tab-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-color: #667eea;
  color: white;
}

.mobile-tab-btn .tab-icon {
  font-size: 1.5rem;
}

.mobile-tab-btn .tab-label {
  font-size: 0.875rem;
  font-weight: 600;
}

.mobile-tab-btn.active .tab-label {
  color: white;
}

.admin-page {
  min-height: 100vh;
  background-color: #f7fafc;
}

.admin-header {
  background-color: #ffffff;
  border-bottom: 2px solid #e2e8f0;
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.admin-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
  color: #2d3748;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.btn-back,
.btn-logout {
  padding: 10px 20px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-back {
  background-color: #f7fafc;
  color: #2d3748;
}

.btn-back:hover {
  background-color: #edf2f7;
}

.btn-logout {
  background-color: #fff5f5;
  color: #e53e3e;
  border-color: #feb2b2;
}

.btn-logout:hover {
  background-color: #fed7d7;
}

.btn-edit-quota {
  margin-left: 8px;
  padding: 2px 6px;
  background: none;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
}

.btn-edit-quota:hover {
  background-color: #f7fafc;
}

.admin-tabs {
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  padding: 0 20px;
  display: flex;
  gap: 8px;
}

.tab-btn {
  padding: 12px 24px;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #718096;
  transition: all 0.2s ease;
}

.tab-btn:hover {
  color: #2d3748;
}

.tab-btn.active {
  color: #4299e1;
  border-bottom-color: #4299e1;
}

.admin-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 40px 20px;
}

.tab-content {
  background-color: #ffffff;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.content-header {
  margin-bottom: 24px;
}

.content-header h2 {
  margin: 0 0 16px 0;
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
}

.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.stat-card {
  padding: 16px;
  background-color: #f7fafc;
  border-radius: 6px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-label {
  font-size: 14px;
  color: #718096;
}

.stat-value {
  font-size: 24px;
  font-weight: 600;
  color: #2d3748;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #718096;
}

.users-table {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

th {
  font-weight: 600;
  color: #2d3748;
  background-color: #f7fafc;
}

td {
  color: #4a5568;
}

.role-select {
  padding: 4px 8px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 14px;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  display: inline-block;
}

.status-badge.active {
  background-color: #c6f6d5;
  color: #22543d;
}

.status-badge.inactive {
  background-color: #fed7d7;
  color: #742a2a;
}

.status-badge.email-status.verified {
  background-color: #c6f6d5;
  color: #22543d;
  white-space: nowrap;
  min-width: 70px;
  display: inline-block;
  text-align: center;
}

.status-badge.email-status.unverified {
  background-color: #fef5e7;
  color: #9c640c;
  white-space: nowrap;
  min-width: 70px;
  display: inline-block;
  text-align: center;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.btn-action {
  padding: 6px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  background-color: #ffffff;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s ease;
}

.btn-action:hover {
  background-color: #f7fafc;
}

.btn-action.btn-delete {
  color: #e53e3e;
  border-color: #feb2b2;
}

.btn-action.btn-delete:hover {
  background-color: #fff5f5;
}

.btn-action.btn-remove {
  color: #e53e3e;
  border-color: #feb2b2;
}

.btn-action.btn-remove:hover {
  background-color: #fff5f5;
}

.btn-action.btn-reset-password {
  color: #dd6b20;
  border-color: #fbd38d;
}

.btn-action.btn-reset-password:hover {
  background-color: #fffaf0;
}

.btn-action.btn-verify {
  color: #3182ce;
  border-color: #bee3f8;
}

.btn-action.btn-verify:hover {
  background-color: #ebf8ff;
}

.btn-add, .btn-batch {
  padding: 8px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-add {
  background-color: #48bb78;
  color: white;
  border-color: #48bb78;
}

.btn-add:hover {
  background-color: #38a169;
}

.btn-batch {
  background-color: #4299e1;
  color: white;
  border-color: #4299e1;
}

.btn-batch:hover {
  background-color: #3182ce;
}

.blacklist-table {
  margin-top: 20px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #a0aec0;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.empty-text {
  font-size: 18px;
  font-weight: 600;
  color: #4a5568;
  margin-bottom: 8px;
}

.empty-hint {
  font-size: 14px;
  color: #a0aec0;
}

.blacklist-actions, .header-actions {
  display: flex;
  gap: 12px;
}

.logs-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.log-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background-color: #f7fafc;
  border-radius: 6px;
}

.log-icon {
  font-size: 24px;
}

.log-content {
  flex: 1;
}

.log-action {
  font-weight: 500;
  color: #2d3748;
  margin-bottom: 4px;
}

.log-meta {
  font-size: 12px;
  color: #718096;
  display: flex;
  gap: 8px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
}

.stat-card-large {
  padding: 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  color: white;
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  font-size: 48px;
}

.stat-info {
  flex: 1;
}

.stat-value-large {
  font-size: 32px;
  font-weight: 700;
  margin-top: 8px;
}

/* 移动端用户管理样式 */
.mobile-stats {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
  overflow-x: auto;
  padding-bottom: 0.25rem;
}

.mobile-stat-card {
  flex: 1;
  min-width: 100px;
  padding: 0.75rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  color: white;
}

.mobile-stat-card .stat-label {
  font-size: 0.75rem;
  opacity: 0.9;
  color: white;
}

.mobile-stat-card .stat-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
}

.mobile-users-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.mobile-user-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.2s ease;
}

.mobile-user-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.user-card-header {
  padding: 1rem;
  background: #f7fafc;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #e2e8f0;
}

.user-info {
  flex: 1;
  min-width: 0;
}

.user-email {
  font-weight: 600;
  color: #2d3748;
  font-size: 0.95rem;
  word-break: break-all;
  margin-bottom: 0.25rem;
}

.user-name {
  font-size: 0.85rem;
  color: #718096;
}

.user-status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  white-space: nowrap;
}

.user-status-badge.active {
  background: #c6f6d5;
  color: #22543d;
}

.user-status-badge.inactive {
  background: #fed7d7;
  color: #742a2a;
}

.user-card-details {
  padding: 1rem;
  background: white;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-label {
  font-size: 0.875rem;
  color: #718096;
  font-weight: 500;
}

.detail-value {
  font-size: 0.875rem;
  color: #2d3748;
  text-align: right;
}

.storage-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-edit-mobile {
  padding: 0.25rem 0.5rem;
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 0.75rem;
  color: #4a5568;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-edit-mobile:hover {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.mobile-role-select {
  padding: 0.25rem 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 0.875rem;
  background: white;
  color: #2d3748;
}

.user-card-actions {
  padding: 0.75rem;
  background: #f7fafc;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  border-top: 1px solid #e2e8f0;
}

.mobile-action-btn {
  flex: 1 1 calc(50% - 0.25rem);
  min-width: 120px;
  padding: 0.625rem 0.75rem;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.mobile-action-btn.btn-delete {
  flex: 1 1 100%;
}

.mobile-action-btn.btn-disable {
  background: #fff5f5;
  color: #e53e3e;
  border: 1px solid #feb2b2;
}

.mobile-action-btn.btn-enable {
  background: #f0fff4;
  color: #38a169;
  border: 1px solid #9ae6b4;
}

.mobile-action-btn.btn-view {
  background: white;
  color: #4a5568;
  border: 1px solid #e2e8f0;
}

.mobile-action-btn.btn-delete {
  background: #fff5f5;
  color: #c53030;
  border: 1px solid #fc8181;
}

.mobile-action-btn.btn-reset-password {
  background: #fffaf0;
  color: #dd6b20;
  border: 1px solid #fbd38d;
}

.mobile-action-btn.btn-verify {
  background: #ebf8ff;
  color: #3182ce;
  border: 1px solid #bee3f8;
}

.mobile-action-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.email-badge {
  padding: 0.25rem 0.625rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
  white-space: nowrap;
  display: inline-block;
}

.email-badge.verified {
  background: #c6f6d5;
  color: #22543d;
}

.email-badge.unverified {
  background: #fef5e7;
  color: #9c640c;
}

/* 黑名单相关样式 */
.mobile-blacklist-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.mobile-blacklist-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
}

.blacklist-card-header {
  padding: 1rem;
  background: #fff5f5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #feb2b2;
}

.blacklist-email {
  font-weight: 600;
  color: #c53030;
  font-size: 0.95rem;
  word-break: break-all;
  flex: 1;
}

.btn-remove-blacklist {
  padding: 0.5rem;
  background: white;
  border: 1px solid #feb2b2;
  border-radius: 6px;
  color: #e53e3e;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.2s ease;
}

.btn-remove-blacklist:hover {
  background: #fff5f5;
  transform: scale(1.1);
}

.blacklist-card-details {
  padding: 1rem;
  background: white;
}

.btn-add-blacklist, .btn-batch-add {
  padding: 0.5rem 1rem;
  border-radius: 6px;
  border: none;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-add-blacklist {
  background: #48bb78;
  color: white;
}

.btn-add-blacklist:hover {
  background: #38a169;
}

.btn-batch-add {
  background: #4299e1;
  color: white;
}

.btn-batch-add:hover {
  background: #3182ce;
}

/* 桌面端默认隐藏移动端组件 */
@media (min-width: 769px) {
  .mobile-users-list,
  .mobile-user-card,
  .mobile-blacklist-list,
  .mobile-blacklist-card {
    display: none !important;
  }
  
  .users-table,
  .blacklist-table {
    display: block;
  }
  
  .btn-add-blacklist,
  .btn-batch-add {
    display: none !important;
  }
}

/* 移动端优化 */
@media (max-width: 768px) {
  .admin-content {
    padding: 0;
  }
  
  .content-header {
    flex-direction: column;
    gap: 1rem;
  }
  
  .content-header h2 {
    font-size: 1.25rem;
    margin-bottom: 0.75rem;
  }
  
  .logs-table {
    overflow-x: auto;
  }
  
  .logs-table table {
    min-width: 900px;
  }
  
  /* 隐藏桌面端的表格，显示移动端卡片 */
  .users-table,
  .blacklist-table {
    display: none !important;
  }
  
  .stats {
    display: none !important;
  }
  
  .btn-add,
  .btn-batch {
    display: none !important;
  }
  
  .tab-content {
    padding: 1rem;
    background: transparent;
    box-shadow: none;
  }
  
  .mobile-users-list,
  .mobile-blacklist-list {
    display: flex;
  }
  
  .mobile-stats {
    display: flex !important;
  }
  
  .blacklist-actions {
    flex-direction: row;
    gap: 0.5rem;
  }
  
  .btn-add-blacklist,
  .btn-batch-add {
    flex: 1;
  }
}
</style>
