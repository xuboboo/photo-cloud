<template>
  <div class="dashboard-page">
    <!-- 桌面端布局 -->
    <div class="desktop-layout">
      <!-- 顶部导航栏 -->
      <header class="dashboard-header">
        <div class="header-container">
          <div class="header-left">
            <div class="logo">
              <span class="logo-icon">📁</span>
              <span class="logo-text">文件管理系统</span>
            </div>
          </div>
          
          <div class="header-right">
            <button v-if="isAdmin" @click="router.push('/admin')" class="btn btn-ghost">
              <span>🛡️</span>
              <span>管理后台</span>
            </button>
            <button @click="router.push('/settings')" class="btn btn-ghost">
              <span>⚙️</span>
              <span>设置</span>
            </button>
            <button @click="handleLogout" class="btn btn-ghost logout-btn">
              <span>👋</span>
              <span>退出</span>
            </button>
          </div>
        </div>
      </header>

      <!-- 主内容区 -->
      <main class="dashboard-main">
        <div class="main-container">
          <!-- 快速操作区 -->
          <section class="quick-actions">
            <button @click="router.push('/create')" class="action-card action-create">
              <div class="action-icon">📝</div>
              <div class="action-content">
                <h3>新建文档</h3>
                <p>创建 Markdown、代码等文档</p>
              </div>
            </button>
            
            <button @click="router.push('/upload')" class="action-card action-upload">
              <div class="action-icon">📤</div>
              <div class="action-content">
                <h3>上传文件</h3>
                <p>上传图片、文档等文件</p>
              </div>
            </button>
            
            <div class="action-card action-stats">
              <div class="action-icon">📊</div>
              <div class="action-content">
                <h3>{{ files.length }}</h3>
                <p>总文件数</p>
              </div>
            </div>
            
            <div class="action-card action-storage">
              <div class="action-icon">💾</div>
              <div class="action-content">
                <h3>{{ storageUsed }}</h3>
                <p>已使用空间</p>
              </div>
            </div>
          </section>

          <!-- 文件列表区 -->
          <section class="files-section">
            <div class="section-header">
              <h2>我的文件</h2>
              <div class="section-actions">
                <div class="search-box">
                  <span class="search-icon">🔍</span>
                  <input 
                    v-model="searchQuery" 
                    type="text" 
                    placeholder="搜索文件..." 
                    class="search-input"
                  />
                </div>
                <select v-model="filterType" class="filter-select">
                  <option value="all">全部文件</option>
                  <option value="images">图片</option>
                  <option value="markdown">文档</option>
                </select>
              </div>
            </div>
            
            <FileList ref="fileListRef" :search="searchQuery" :filter="filterType" @files-loaded="handleFilesLoaded" />
          </section>
        </div>
      </main>
      
      <!-- 页脚 -->
      <Footer />
    </div>

    <!-- 移动端布局 -->
    <div class="mobile-layout">
      <!-- 顶部标题栏 -->
      <header class="mobile-header">
        <h1>文件管理</h1>
        <button @click="handleLogout" class="logout-btn-mobile">
          退出登录
        </button>
      </header>

      <!-- Tab 内容 -->
      <div class="tab-content">
        <!-- 首页 Tab -->
        <div v-show="activeTab === 'home'" class="tab-panel">
          <div class="mobile-search">
            <span class="search-icon">🔍</span>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="搜索文件..." 
              class="search-input"
            />
          </div>
          
          <div class="filter-chips">
            <button 
              v-for="type in filterTypes" 
              :key="type.value"
              @click="filterType = type.value"
              :class="['chip', { active: filterType === type.value }]"
            >
              {{ type.label }}
            </button>
          </div>
          
          <FileList ref="fileListRef" :search="searchQuery" :filter="filterType" @files-loaded="handleFilesLoaded" />
        </div>

        <!-- 新建 Tab -->
        <div v-show="activeTab === 'create'" class="tab-panel">
          <div class="action-list">
            <button @click="router.push('/create')" class="action-item">
              <div class="action-item-icon">📝</div>
              <div class="action-item-content">
                <h3>新建文档</h3>
                <p>创建 Markdown、代码等文档</p>
              </div>
              <div class="action-item-arrow">›</div>
            </button>
            
            <button @click="router.push('/upload')" class="action-item">
              <div class="action-item-icon">📤</div>
              <div class="action-item-content">
                <h3>上传文件</h3>
                <p>上传图片、文档等文件</p>
              </div>
              <div class="action-item-arrow">›</div>
            </button>
          </div>
        </div>

        <!-- 统计 Tab -->
        <div v-show="activeTab === 'stats'" class="tab-panel">
          <div class="stats-cards">
            <div class="stat-card">
              <div class="stat-icon">📁</div>
              <div class="stat-value">{{ files.length }}</div>
              <div class="stat-label">总文件数</div>
            </div>
            
            <div class="stat-card">
              <div class="stat-icon">💾</div>
              <div class="stat-value">{{ storageUsed }}</div>
              <div class="stat-label">已使用空间</div>
            </div>
            
            <div class="stat-card">
              <div class="stat-icon">🖼️</div>
              <div class="stat-value">{{ imageCount }}</div>
              <div class="stat-label">图片文件</div>
            </div>
            
            <div class="stat-card">
              <div class="stat-icon">📝</div>
              <div class="stat-value">{{ markdownCount }}</div>
              <div class="stat-label">文档文件</div>
            </div>
          </div>
        </div>

        <!-- 设置 Tab -->
        <div v-show="activeTab === 'settings'" class="tab-panel">
          <div class="settings-list">
            <button @click="router.push('/settings')" class="settings-item">
              <div class="settings-icon">⚙️</div>
              <div class="settings-content">
                <h3>个人设置</h3>
                <p>账户信息、存储空间</p>
              </div>
              <div class="settings-arrow">›</div>
            </button>
            
            <button v-if="isAdmin" @click="router.push('/admin')" class="settings-item">
              <div class="settings-icon">🛡️</div>
              <div class="settings-content">
                <h3>管理后台</h3>
                <p>用户管理、系统设置</p>
              </div>
              <div class="settings-arrow">›</div>
            </button>
            
            <button @click="handleLogout" class="settings-item danger">
              <div class="settings-icon">🚪</div>
              <div class="settings-content">
                <h3>退出登录</h3>
                <p>安全退出当前账户</p>
              </div>
              <div class="settings-arrow">›</div>
            </button>
          </div>
        </div>
      </div>

      <!-- Tab 切换 - 底部导航栏 -->
      <div class="tab-bar">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="['tab-item', { active: activeTab === tab.id }]"
        >
          <span class="tab-icon">{{ tab.icon }}</span>
          <span class="tab-label">{{ tab.label }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import { supabase } from '../api/supabase'
import FileList from '../components/FileList.vue'
import Footer from '../components/Footer.vue'

const router = useRouter()
const userStore = useUserStore()
const fileListRef = ref(null)
const isAdmin = ref(false)
const searchQuery = ref('')
const filterType = ref('all')
const files = ref([])
const activeTab = ref('home')

const tabs = [
  { id: 'home', icon: '🏠', label: '文件' },
  { id: 'create', icon: '📤', label: '上传' },
  { id: 'stats', icon: '📊', label: '用量' },
  { id: 'settings', icon: '👤', label: '我的' }
]

const filterTypes = [
  { value: 'all', label: '全部' },
  { value: 'images', label: '图片' },
  { value: 'markdown', label: '文档' }
]

const storageUsed = computed(() => {
  const totalSize = files.value.reduce((sum, file) => sum + (file.size || 0), 0)
  return formatBytes(totalSize)
})

const imageCount = computed(() => {
  return files.value.filter(f => f.type === 'images').length
})

const markdownCount = computed(() => {
  return files.value.filter(f => f.type === 'markdown').length
})

onMounted(async () => {
  await checkAdminRole()
})

async function checkAdminRole() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (user) {
      const { data } = await supabase
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle()
      
      if (data) {
        isAdmin.value = ['admin', 'super_admin'].includes(data.role)
      }
    }
  } catch (error) {
    console.error('Check admin role error:', error)
  }
}

function handleFilesLoaded(loadedFiles) {
  files.value = loadedFiles
}

async function handleLogout() {
  if (!confirm('确定要退出登录吗？')) return

  try {
    await userStore.logout()
    router.push('/login')
  } catch (err) {
    alert('退出失败：' + err.message)
  }
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}
</script>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background: linear-gradient(to bottom, #f0f9ff 0%, #ffffff 100%);
}

/* 桌面端布局 */
.desktop-layout {
  display: block;
}

.mobile-layout {
  display: none;
}

/* 顶部导航 */
.dashboard-header {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--gray-200);
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: var(--shadow-sm);
}

.header-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 1rem 2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 700;
  font-size: 1.25rem;
  color: var(--gray-900);
}

.logo-icon {
  font-size: 1.75rem;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.logout-btn {
  background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
  color: #dc2626;
  font-weight: 600;
}

.logout-btn:hover {
  background: linear-gradient(135deg, #fecaca 0%, #fca5a5 100%);
  transform: translateY(-1px);
  box-shadow: var(--shadow-sm);
}

/* 主内容区 */
.dashboard-main {
  padding: 2rem;
}

.main-container {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* 快速操作区 */
.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  animation: fadeIn 0.5s ease;
}

.action-card {
  background: white;
  border: 2px solid var(--gray-200);
  border-radius: var(--radius-xl);
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  transition: var(--transition);
  box-shadow: var(--shadow-sm);
}

.action-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
  border-color: var(--primary-300);
}

.action-create {
  background: linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%);
  border: none;
}

.action-upload {
  background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
  border: none;
}

.action-stats {
  background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
  border: none;
  cursor: default;
}

.action-storage {
  background: linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%);
  border: none;
  cursor: default;
}

.action-icon {
  font-size: 2.5rem;
  flex-shrink: 0;
}

.action-content h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--gray-900);
  margin-bottom: 0.25rem;
}

.action-content p {
  font-size: 0.875rem;
  color: var(--gray-600);
}

/* 文件列表区 */
.files-section {
  background: white;
  border-radius: var(--radius-xl);
  padding: 2rem;
  box-shadow: var(--shadow);
  animation: slideUp 0.6s ease;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.section-header h2 {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--gray-900);
}

.section-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 1rem;
  font-size: 1rem;
}

.search-input {
  padding: 0.625rem 1rem 0.625rem 2.75rem;
  border: 1px solid var(--gray-300);
  border-radius: var(--radius-full);
  font-size: 0.875rem;
  width: 250px;
  transition: var(--transition);
}

.search-input:focus {
  outline: none;
  border-color: var(--primary-500);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  width: 300px;
}

.filter-select {
  padding: 0.625rem 1rem;
  border: 1px solid var(--gray-300);
  border-radius: var(--radius-md);
  font-size: 0.875rem;
  background-color: white;
  cursor: pointer;
  transition: var(--transition);
}

.filter-select:focus {
  outline: none;
  border-color: var(--primary-500);
}

/* 移动端布局 */
@media (max-width: 768px) {
  .desktop-layout {
    display: none;
  }
  
  .mobile-layout {
    display: flex;
    flex-direction: column;
    min-height: 100%;
  }
  
  .mobile-header {
    background: white;
    padding: 1rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid var(--gray-200);
    box-shadow: var(--shadow-sm);
  }
  
  .mobile-header h1 {
    font-size: 1.25rem;
    font-weight: 700;
    color: var(--gray-900);
  }
  
  .logout-btn-mobile {
    padding: 0.5rem 1rem;
    background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
    color: #dc2626;
    border: none;
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 600;
    cursor: pointer;
    transition: var(--transition);
    box-shadow: var(--shadow-sm);
  }
  
  .logout-btn-mobile:active {
    transform: scale(0.95);
    background: linear-gradient(135deg, #fecaca 0%, #fca5a5 100%);
  }
  
  /* Tab 栏 - 底部固定 */
  .tab-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    display: flex;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-top: 1px solid var(--gray-200);
    padding: 0.5rem;
    padding-bottom: calc(0.5rem + env(safe-area-inset-bottom));
    gap: 0.5rem;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.05);
    z-index: 100;
  }
  
  .tab-item {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.25rem;
    padding: 0.75rem 0.5rem;
    background: none;
    border: none;
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: var(--transition);
    color: var(--gray-600);
  }
  
  .tab-item.active {
    background: var(--primary-50);
    color: var(--primary-600);
  }
  
  .tab-icon {
    font-size: 1.5rem;
  }
  
  .tab-label {
    font-size: 0.75rem;
    font-weight: 500;
  }
  
  /* Tab 内容 */
  .tab-content {
    flex: 1;
    overflow-y: auto;
    background: var(--gray-50);
    padding-bottom: calc(70px + env(safe-area-inset-bottom));
  }
  
  .tab-panel {
    padding: 1rem;
    animation: fadeIn 0.3s ease;
  }
  
  /* 搜索栏 */
  .mobile-search {
    position: relative;
    margin-bottom: 1rem;
  }
  
  .mobile-search .search-input {
    width: 100%;
    padding: 0.875rem 1rem 0.875rem 3rem;
    border: 1px solid var(--gray-300);
    border-radius: var(--radius-lg);
    font-size: 1rem;
    background: white;
  }
  
  .mobile-search .search-icon {
    position: absolute;
    left: 1rem;
    top: 50%;
    transform: translateY(-50%);
    font-size: 1.25rem;
  }
  
  /* 筛选芯片 */
  .filter-chips {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
    overflow-x: auto;
    padding-bottom: 0.5rem;
  }
  
  .chip {
    padding: 0.5rem 1rem;
    background: white;
    border: 1px solid var(--gray-300);
    border-radius: var(--radius-full);
    font-size: 0.875rem;
    font-weight: 500;
    white-space: nowrap;
    cursor: pointer;
    transition: var(--transition);
  }
  
  .chip.active {
    background: var(--primary-500);
    color: white;
    border-color: var(--primary-500);
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
    border: none;
    border-radius: var(--radius-lg);
    cursor: pointer;
    transition: var(--transition);
    box-shadow: var(--shadow-sm);
  }
  
  .action-item:active {
    transform: scale(0.98);
  }
  
  .action-item-icon {
    font-size: 2rem;
    flex-shrink: 0;
  }
  
  .action-item-content {
    flex: 1;
    text-align: left;
  }
  
  .action-item-content h3 {
    font-size: 1rem;
    font-weight: 600;
    color: var(--gray-900);
    margin-bottom: 0.25rem;
  }
  
  .action-item-content p {
    font-size: 0.875rem;
    color: var(--gray-600);
  }
  
  .action-item-arrow {
    font-size: 1.5rem;
    color: var(--gray-400);
  }
  
  /* 统计卡片 */
  .stats-cards {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
  
  .stat-card {
    background: white;
    border-radius: var(--radius-lg);
    padding: 1.5rem;
    text-align: center;
    box-shadow: var(--shadow-sm);
  }
  
  .stat-icon {
    font-size: 2.5rem;
    margin-bottom: 0.75rem;
  }
  
  .stat-value {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--gray-900);
    margin-bottom: 0.25rem;
  }
  
  .stat-label {
    font-size: 0.875rem;
    color: var(--gray-600);
  }
  
  /* 设置列表 */
  .settings-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }
  
  .settings-item {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1.25rem;
    background: white;
    border: none;
    border-radius: var(--radius-lg);
    cursor: pointer;
    transition: var(--transition);
    box-shadow: var(--shadow-sm);
  }
  
  .settings-item:active {
    transform: scale(0.98);
  }
  
  .settings-item.danger {
    background: #fff5f5;
  }
  
  .settings-icon {
    font-size: 2rem;
    flex-shrink: 0;
  }
  
  .settings-content {
    flex: 1;
    text-align: left;
  }
  
  .settings-content h3 {
    font-size: 1rem;
    font-weight: 600;
    color: var(--gray-900);
    margin-bottom: 0.25rem;
  }
  
  .settings-content p {
    font-size: 0.875rem;
    color: var(--gray-600);
  }
  
  .settings-arrow {
    font-size: 1.5rem;
    color: var(--gray-400);
  }
}
</style>
