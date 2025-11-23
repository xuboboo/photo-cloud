<template>
  <MobileLayout title="我的" :show-back="false">
    <!-- 移动端内容 -->
    <div class="settings-mobile-content">
      <div class="settings-content">
      <!-- 存储空间卡片 -->
      <div class="settings-card">
        <div class="card-header">
          <h2>💾 存储空间</h2>
        </div>
        <div class="card-body">
          <div v-if="loading" class="loading">加载中...</div>
          <div v-else-if="profile">
            <div class="storage-info">
              <div class="storage-visual">
                <div class="storage-bar">
                  <div 
                    class="storage-used" 
                    :style="{ width: storagePercentage + '%' }"
                    :class="{ warning: storagePercentage > 80, danger: storagePercentage > 95 }"
                  ></div>
                </div>
                <div class="storage-text">
                  <span class="used">{{ formatFileSize(profile.storage_used) }}</span>
                  <span class="separator">/</span>
                  <span class="total">{{ formatFileSize(profile.storage_quota) }}</span>
                  <span class="percentage">({{ storagePercentage }}%)</span>
                </div>
              </div>

              <div class="storage-stats">
                <div class="stat-item">
                  <span class="stat-label">已使用</span>
                  <span class="stat-value">{{ formatFileSize(profile.storage_used) }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">剩余空间</span>
                  <span class="stat-value">{{ formatFileSize(profile.storage_quota - profile.storage_used) }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">总配额</span>
                  <span class="stat-value">{{ formatFileSize(profile.storage_quota) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 账户信息卡片 -->
      <div class="settings-card">
        <div class="card-header">
          <h2>👤 账户信息</h2>
        </div>
        <div class="card-body">
          <div v-if="loading" class="loading">加载中...</div>
          <div v-else-if="user && profile">
            <div class="info-grid">
              <div class="info-item">
                <label>邮箱</label>
                <div class="info-value">{{ user.email }}</div>
              </div>
              <div class="info-item">
                <label>显示名称</label>
                <div class="info-value">
                  <input 
                    v-model="displayName" 
                    type="text" 
                    placeholder="设置显示名称"
                    class="input-field"
                  />
                  <button @click="updateDisplayName" class="btn-save">保存</button>
                </div>
              </div>
              <div class="info-item">
                <label>账户角色</label>
                <div class="info-value">
                  <span class="role-badge" :class="'role-' + profile.role">
                    {{ getRoleText(profile.role) }}
                  </span>
                </div>
              </div>
              <div class="info-item">
                <label>账户状态</label>
                <div class="info-value">
                  <span :class="['status-badge', profile.is_active ? 'active' : 'inactive']">
                    {{ profile.is_active ? '✓ 正常' : '✗ 已禁用' }}
                  </span>
                </div>
              </div>
              <div class="info-item">
                <label>注册时间</label>
                <div class="info-value">{{ formatDateTime(profile.created_at) }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 修改密码卡片 -->
      <div class="settings-card">
        <div class="card-header">
          <h2>🔐 修改密码</h2>
        </div>
        <div class="card-body">
          <div class="password-form">
            <div class="form-group">
              <label>新密码</label>
              <input 
                v-model="newPassword" 
                type="password" 
                placeholder="至少 6 位"
                minlength="6"
                class="input-field"
              />
            </div>
            <div class="form-group">
              <label>确认密码</label>
              <input 
                v-model="confirmPassword" 
                type="password" 
                placeholder="再次输入新密码"
                class="input-field"
              />
            </div>
            <button @click="changePassword" :disabled="changingPassword" class="btn-primary">
              {{ changingPassword ? '修改中...' : '修改密码' }}
            </button>
          </div>
        </div>
      </div>

      <!-- 文件统计卡片 -->
      <div class="settings-card">
        <div class="card-header">
          <h2>📊 文件统计</h2>
        </div>
        <div class="card-body">
          <div v-if="loadingStats" class="loading">加载中...</div>
          <div v-else class="stats-grid">
            <div class="stat-card">
              <div class="stat-icon">📁</div>
              <div class="stat-info">
                <div class="stat-label">总文件数</div>
                <div class="stat-value">{{ fileStats.total }}</div>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon">🖼️</div>
              <div class="stat-info">
                <div class="stat-label">图片文件</div>
                <div class="stat-value">{{ fileStats.images }}</div>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon">📝</div>
              <div class="stat-info">
                <div class="stat-label">Markdown</div>
                <div class="stat-value">{{ fileStats.markdown }}</div>
              </div>
            </div>
            <div class="stat-card">
              <div class="stat-icon">🔗</div>
              <div class="stat-info">
                <div class="stat-label">分享链接</div>
                <div class="stat-value">{{ fileStats.shares }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 操作列表 -->
      <div class="settings-card">
        <div class="card-header">
          <h2>⚙️ 更多操作</h2>
        </div>
        <div class="card-body">
          <div class="action-list">
            <button v-if="isAdmin" @click="router.push('/admin')" class="action-item">
              <div class="action-item-icon">🛡️</div>
              <div class="action-item-content">
                <h3>管理后台</h3>
                <p>用户管理、系统设置</p>
              </div>
              <div class="action-item-arrow">›</div>
            </button>
            
            <button @click="handleLogout" class="action-item action-danger">
              <div class="action-item-icon">🚪</div>
              <div class="action-item-content">
                <h3>退出登录</h3>
                <p>安全退出当前账户</p>
              </div>
              <div class="action-item-arrow">›</div>
            </button>
          </div>
        </div>
      </div>
      </div>
    </div>
    
    <!-- 桌面端内容 -->
    <template #desktop>
      <div class="settings-page">
        <div class="settings-header">
          <button @click="handleBack" class="btn-back">← 返回</button>
          <h1>⚙️ 个人设置</h1>
        </div>

        <div class="settings-content">
          <!-- 存储空间卡片 -->
          <div class="settings-card">
            <div class="card-header">
              <h2>💾 存储空间</h2>
            </div>
            <div class="card-body">
              <div v-if="loading" class="loading">加载中...</div>
              <div v-else-if="profile">
                <div class="storage-info">
                  <div class="storage-visual">
                    <div class="storage-bar">
                      <div 
                        class="storage-used" 
                        :style="{ width: storagePercentage + '%' }"
                        :class="{ warning: storagePercentage > 80, danger: storagePercentage > 95 }"
                      ></div>
                    </div>
                    <div class="storage-text">
                      <span class="used">{{ formatFileSize(profile.storage_used) }}</span>
                      <span class="separator">/</span>
                      <span class="total">{{ formatFileSize(profile.storage_quota) }}</span>
                      <span class="percentage">({{ storagePercentage }}%)</span>
                    </div>
                  </div>

                  <div class="storage-stats">
                    <div class="stat-item">
                      <span class="stat-label">已使用</span>
                      <span class="stat-value">{{ formatFileSize(profile.storage_used) }}</span>
                    </div>
                    <div class="stat-item">
                      <span class="stat-label">剩余空间</span>
                      <span class="stat-value">{{ formatFileSize(profile.storage_quota - profile.storage_used) }}</span>
                    </div>
                    <div class="stat-item">
                      <span class="stat-label">总配额</span>
                      <span class="stat-value">{{ formatFileSize(profile.storage_quota) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 账户信息卡片 -->
          <div class="settings-card">
            <div class="card-header">
              <h2>👤 账户信息</h2>
            </div>
            <div class="card-body">
              <div v-if="loading" class="loading">加载中...</div>
              <div v-else-if="user && profile">
                <div class="info-grid">
                  <div class="info-item">
                    <label>邮箱</label>
                    <div class="info-value">{{ user.email }}</div>
                  </div>
                  <div class="info-item">
                    <label>显示名称</label>
                    <div class="info-value">
                      <input 
                        v-model="displayName" 
                        type="text" 
                        placeholder="设置显示名称"
                        class="input-field"
                      />
                      <button @click="updateDisplayName" class="btn-save">保存</button>
                    </div>
                  </div>
                  <div class="info-item">
                    <label>账户角色</label>
                    <div class="info-value">
                      <span class="role-badge" :class="'role-' + profile.role">
                        {{ getRoleText(profile.role) }}
                      </span>
                    </div>
                  </div>
                  <div class="info-item">
                    <label>账户状态</label>
                    <div class="info-value">
                      <span :class="['status-badge', profile.is_active ? 'active' : 'inactive']">
                        {{ profile.is_active ? '✓ 正常' : '✗ 已禁用' }}
                      </span>
                    </div>
                  </div>
                  <div class="info-item">
                    <label>注册时间</label>
                    <div class="info-value">{{ formatDateTime(profile.created_at) }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 修改密码卡片 -->
          <div class="settings-card">
            <div class="card-header">
              <h2>🔐 修改密码</h2>
            </div>
            <div class="card-body">
              <div class="password-form">
                <div class="form-group">
                  <label>新密码</label>
                  <input 
                    v-model="newPassword" 
                    type="password" 
                    placeholder="至少 6 位"
                    minlength="6"
                    class="input-field"
                  />
                </div>
                <div class="form-group">
                  <label>确认密码</label>
                  <input 
                    v-model="confirmPassword" 
                    type="password" 
                    placeholder="再次输入新密码"
                    class="input-field"
                  />
                </div>
                <button @click="changePassword" :disabled="changingPassword" class="btn-primary">
                  {{ changingPassword ? '修改中...' : '修改密码' }}
                </button>
              </div>
            </div>
          </div>

          <!-- 文件统计卡片 -->
          <div class="settings-card">
            <div class="card-header">
              <h2>📊 文件统计</h2>
            </div>
            <div class="card-body">
              <div v-if="loadingStats" class="loading">加载中...</div>
              <div v-else class="stats-grid">
                <div class="stat-card">
                  <div class="stat-icon">📁</div>
                  <div class="stat-info">
                    <div class="stat-label">总文件数</div>
                    <div class="stat-value">{{ fileStats.total }}</div>
                  </div>
                </div>
                <div class="stat-card">
                  <div class="stat-icon">🖼️</div>
                  <div class="stat-info">
                    <div class="stat-label">图片文件</div>
                    <div class="stat-value">{{ fileStats.images }}</div>
                  </div>
                </div>
                <div class="stat-card">
                  <div class="stat-icon">📝</div>
                  <div class="stat-info">
                    <div class="stat-label">Markdown</div>
                    <div class="stat-value">{{ fileStats.markdown }}</div>
                  </div>
                </div>
                <div class="stat-card">
                  <div class="stat-icon">🔗</div>
                  <div class="stat-info">
                    <div class="stat-label">分享链接</div>
                    <div class="stat-value">{{ fileStats.shares }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <Footer />
      </div>
    </template>
  </MobileLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import MobileLayout from '../layouts/MobileLayout.vue'
import Footer from '../components/Footer.vue'
import { supabase } from '../api/supabase'
import { getCurrentUserProfile, updateCurrentUserProfile } from '../api/admin'
import { getFiles } from '../api/files'
import { getUserShares } from '../api/shares'
import { formatFileSize, formatDateTime } from '../utils/helpers'

const router = useRouter()

const loading = ref(true)
const loadingStats = ref(true)
const changingPassword = ref(false)
const user = ref(null)
const profile = ref(null)
const displayName = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const isAdmin = ref(false)
const fileStats = ref({
  total: 0,
  images: 0,
  markdown: 0,
  shares: 0
})

const storagePercentage = computed(() => {
  if (!profile.value) return 0
  const percentage = (profile.value.storage_used / profile.value.storage_quota) * 100
  return Math.min(Math.round(percentage), 100)
})

onMounted(async () => {
  await loadUserData()
  await loadFileStats()
})

async function loadUserData() {
  try {
    loading.value = true
    
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    user.value = currentUser
    
    profile.value = await getCurrentUserProfile()
    displayName.value = profile.value.display_name || ''
    
    // 检查管理员权限
    isAdmin.value = ['admin', 'super_admin'].includes(profile.value.role)
  } catch (error) {
    console.error('Load user data error:', error)
    alert('加载用户信息失败')
  } finally {
    loading.value = false
  }
}

async function loadFileStats() {
  try {
    loadingStats.value = true
    
    const files = await getFiles()
    const shares = await getUserShares()
    
    fileStats.value = {
      total: files.length,
      images: files.filter(f => f.type === 'images').length,
      markdown: files.filter(f => f.type === 'markdown').length,
      shares: shares.length
    }
  } catch (error) {
    console.error('Load file stats error:', error)
  } finally {
    loadingStats.value = false
  }
}

async function updateDisplayName() {
  try {
    await updateCurrentUserProfile({ display_name: displayName.value })
    alert('显示名称更新成功')
    await loadUserData()
  } catch (error) {
    alert('更新失败：' + error.message)
  }
}

async function changePassword() {
  if (newPassword.value.length < 6) {
    alert('密码至少需要 6 位')
    return
  }
  
  if (newPassword.value !== confirmPassword.value) {
    alert('两次输入的密码不一致')
    return
  }
  
  if (!confirm('确定要修改密码吗？')) return
  
  try {
    changingPassword.value = true
    
    const { error } = await supabase.auth.updateUser({
      password: newPassword.value
    })
    
    if (error) throw error
    
    alert('密码修改成功！')
    newPassword.value = ''
    confirmPassword.value = ''
  } catch (error) {
    alert('密码修改失败：' + error.message)
  } finally {
    changingPassword.value = false
  }
}

function getRoleText(role) {
  const roles = {
    'user': '普通用户',
    'admin': '管理员',
    'super_admin': '超级管理员'
  }
  return roles[role] || role
}

function handleBack() {
  // 如果有历史记录，返回上一页；否则返回工作台
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/dashboard')
  }
}

async function handleLogout() {
  if (!confirm('确定要退出登录吗？')) return

  try {
    await supabase.auth.signOut()
    router.push('/login')
  } catch (err) {
    alert('退出失败：' + err.message)
  }
}

</script>

<style scoped>
.settings-page {
  min-height: 100vh;
  background-color: #f7fafc;
  padding: 20px;
}

.settings-header {
  max-width: 1000px;
  margin: 0 auto 30px;
  display: flex;
  align-items: center;
  gap: 20px;
}

.settings-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
  color: #2d3748;
}

.btn-back {
  padding: 10px 20px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #2d3748;
  transition: all 0.2s ease;
}

.btn-back:hover {
  background-color: #f7fafc;
}

.settings-content {
  max-width: 1000px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.settings-card {
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.card-header {
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.card-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
}

.card-body {
  padding: 24px;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #718096;
}

/* 存储空间样式 */
.storage-info {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.storage-visual {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.storage-bar {
  height: 24px;
  background-color: #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
}

.storage-used {
  height: 100%;
  background: linear-gradient(90deg, #4299e1 0%, #667eea 100%);
  transition: width 0.3s ease;
}

.storage-used.warning {
  background: linear-gradient(90deg, #ed8936 0%, #f6ad55 100%);
}

.storage-used.danger {
  background: linear-gradient(90deg, #e53e3e 0%, #fc8181 100%);
}

.storage-text {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
}

.storage-text .used {
  font-weight: 600;
  color: #2d3748;
}

.storage-text .separator {
  color: #cbd5e0;
}

.storage-text .total {
  color: #718096;
}

.storage-text .percentage {
  margin-left: auto;
  font-weight: 600;
  color: #4299e1;
}

.storage-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px;
}

.stat-item {
  padding: 16px;
  background-color: #f7fafc;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-label {
  font-size: 14px;
  color: #718096;
}

.stat-value {
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
}

/* 账户信息样式 */
.info-grid {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.info-item label {
  font-size: 14px;
  font-weight: 500;
  color: #718096;
}

.info-value {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 16px;
  color: #2d3748;
}

.input-field {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 14px;
  transition: all 0.2s ease;
}

.input-field:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
}

.btn-save {
  padding: 10px 20px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-save:hover {
  background-color: #3182ce;
}

.role-badge {
  padding: 6px 12px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
}

.role-user {
  background-color: #e6fffa;
  color: #234e52;
}

.role-admin {
  background-color: #fef5e7;
  color: #744210;
}

.role-super_admin {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
}

.status-badge.active {
  background-color: #c6f6d5;
  color: #22543d;
}

.status-badge.inactive {
  background-color: #fed7d7;
  color: #742a2a;
}

/* 修改密码样式 */
.password-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
  max-width: 400px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 14px;
  font-weight: 500;
  color: #718096;
}

.btn-primary {
  padding: 12px 24px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-primary:hover:not(:disabled) {
  background-color: #3182ce;
}

.btn-primary:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

/* 文件统计样式 */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.stat-card {
  padding: 20px;
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-icon {
  font-size: 36px;
}

.stat-info {
  flex: 1;
}

.stat-info .stat-label {
  font-size: 14px;
  color: #718096;
  margin-bottom: 4px;
}

.stat-info .stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #2d3748;
}

/* 操作列表 */
.action-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.action-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
  width: 100%;
}

.action-item:hover {
  background: #f7fafc;
  border-color: #cbd5e0;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.action-item:active {
  transform: translateY(0);
}

.action-item-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.action-item-content {
  flex: 1;
}

.action-item-content h3 {
  font-size: 1rem;
  font-weight: 600;
  color: #2d3748;
  margin: 0 0 0.25rem 0;
}

.action-item-content p {
  font-size: 0.875rem;
  color: #718096;
  margin: 0;
}

.action-item-arrow {
  font-size: 1.5rem;
  color: #cbd5e0;
}

.action-danger {
  border-color: #fed7d7;
  background: #fff5f5;
}

.action-danger:hover {
  background: #fee2e2;
  border-color: #fca5a5;
}

.action-danger .action-item-content h3 {
  color: #e53e3e;
}

/* 移动端内容 */
.settings-mobile-content {
  padding: 1rem;
}

.settings-mobile-content .settings-content {
  max-width: 100%;
  gap: 1rem;
}

/* 移动端优化 */
@media (max-width: 768px) {
  .settings-page {
    padding: 1rem;
  }
  
  .settings-header {
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
  }
  
  .settings-header h1 {
    font-size: 1.5rem;
  }
  
  .btn-back {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
  }
  
  .settings-content {
    gap: 1rem;
  }
  
  .settings-card {
    border-radius: var(--radius-lg);
  }
  
  .card-header {
    padding: 1rem;
  }
  
  .card-header h2 {
    font-size: 1.125rem;
  }
  
  .card-body {
    padding: 1rem;
  }
  
  .storage-stats {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 0.75rem;
  }
  
  .stat-card {
    padding: 1rem;
    flex-direction: column;
    text-align: center;
  }
  
  .stat-icon {
    font-size: 2rem;
  }
  
  .stat-info .stat-value {
    font-size: 1.5rem;
  }
  
  .password-form {
    max-width: 100%;
  }
  
  .info-value {
    flex-direction: column;
    align-items: stretch;
  }
  
  .input-field {
    font-size: 1rem;
  }
  
  .btn-save,
  .btn-primary {
    padding: 0.875rem 1.5rem;
    font-size: 1rem;
  }
}
</style>
