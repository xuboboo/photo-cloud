<template>
  <div class="mobile-layout-wrapper">
    <!-- 移动端布局 -->
    <div class="mobile-view">
      <!-- 顶部标题栏 -->
      <header class="mobile-header">
        <button v-if="showBack" @click="goBack" class="back-btn">
          ← 返回
        </button>
        <h1>{{ title }}</h1>
        <button @click="handleLogout" class="logout-btn-mobile">
          退出登录
        </button>
      </header>

      <!-- 内容区域 -->
      <div class="mobile-content">
        <slot></slot>
      </div>

      <!-- 底部 Tab 栏 -->
      <nav class="mobile-tab-bar">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          @click="navigateTo(tab.path)"
          :class="['tab-item', { active: isActive(tab.path) }]"
        >
          <span class="tab-icon">{{ tab.icon }}</span>
          <span class="tab-label">{{ tab.label }}</span>
        </button>
      </nav>
    </div>

    <!-- 桌面端布局 -->
    <div class="desktop-view">
      <slot name="desktop">
        <slot></slot>
      </slot>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '../stores/user'

const props = defineProps({
  title: {
    type: String,
    default: '文件管理'
  },
  showBack: {
    type: Boolean,
    default: false
  }
})

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 动态生成Tab栏，根据用户角色决定是否显示管理按钮
const tabs = computed(() => {
  const baseTabs = [
    { id: 'home', icon: '🏠', label: '文件', path: '/dashboard' },
    { id: 'upload', icon: '📤', label: '上传', path: '/upload' },
    { id: 'profile', icon: '👤', label: '我的', path: '/settings' }
  ]
  
  // 如果是管理员，添加管理按钮
  if (userStore.user?.role && ['admin', 'super_admin'].includes(userStore.user.role)) {
    baseTabs.push({ id: 'admin', icon: '⚙️', label: '管理', path: '/admin' })
  }
  
  return baseTabs
})

function isActive(path) {
  if (path === '/dashboard') {
    return route.path === '/dashboard' || route.path === '/'
  }
  return route.path.startsWith(path)
}

function navigateTo(path) {
  if (route.path !== path) {
    router.push(path)
  }
}

function goBack() {
  router.back()
}

async function handleLogout() {
  if (!confirm('确定要退出登录吗？')) return

  try {
    // 立即跳转，不等待API响应
    const logoutPromise = userStore.logout()
    router.push('/login')
    
    // 在后台完成登出
    await logoutPromise
  } catch (err) {
    console.error('退出失败：', err)
    // 即使失败也已经跳转了
  }
}
</script>

<style scoped>
.mobile-layout-wrapper {
  min-height: 100vh;
}

/* 移动端显示 */
.mobile-view {
  display: none;
}

/* 桌面端显示 */
.desktop-view {
  display: block;
}

/* 移动端布局 */
@media (max-width: 768px) {
  .mobile-view {
    display: flex;
    flex-direction: column;
    height: 100vh;
    height: calc(var(--vh, 1vh) * 100);
  }
  
  .desktop-view {
    display: none;
  }
  
  .mobile-header {
    background: white;
    padding: 1rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid var(--gray-200);
    box-shadow: var(--shadow-sm);
    gap: 1rem;
  }
  
  .back-btn {
    padding: 0.5rem 0.75rem;
    background: var(--gray-100);
    border: none;
    border-radius: var(--radius-md);
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--gray-700);
    cursor: pointer;
    transition: var(--transition);
    white-space: nowrap;
  }
  
  .back-btn:active {
    transform: scale(0.95);
    background: var(--gray-200);
  }
  
  .mobile-header h1 {
    flex: 1;
    font-size: 1.125rem;
    font-weight: 700;
    color: var(--gray-900);
    text-align: center;
    margin: 0;
  }
  
  .logout-btn-mobile {
    padding: 0.5rem 0.875rem;
    background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
    color: #dc2626;
    border: none;
    border-radius: var(--radius-md);
    font-size: 0.8125rem;
    font-weight: 600;
    cursor: pointer;
    transition: var(--transition);
    box-shadow: var(--shadow-sm);
    white-space: nowrap;
  }
  
  .logout-btn-mobile:active {
    transform: scale(0.95);
    background: linear-gradient(135deg, #fecaca 0%, #fca5a5 100%);
  }
  
  .mobile-content {
    flex: 1;
    overflow-y: auto;
    background: var(--gray-50);
    padding-bottom: calc(70px + env(safe-area-inset-bottom));
  }
  
  .mobile-tab-bar {
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
    padding: 0.5rem;
    background: none;
    border: none;
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: var(--transition);
    color: var(--gray-600);
  }
  
  .tab-item:active {
    transform: scale(0.95);
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
}
</style>
