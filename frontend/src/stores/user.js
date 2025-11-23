import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../api/supabase'
import { getUser, logout as apiLogout } from '../api/auth'

export const useUserStore = defineStore('user', () => {
  const user = ref(null)
  const session = ref(null)
  const loading = ref(false)
  let authListener = null // 保存监听器引用以便清理
  let initPromise = null // 保存初始化Promise，避免重复初始化

  const isAuthenticated = computed(() => !!user.value)

  /**
   * 初始化用户状态
   */
  async function initialize() {
    // 如果已经初始化过，返回现有Promise
    if (initPromise) {
      return initPromise
    }

    // 如果已经有监听器，说明已初始化
    if (authListener) {
      return Promise.resolve()
    }

    initPromise = (async () => {
      try {
        loading.value = true
        
        // 获取当前会话（从本地缓存，很快）
        const { data: { session: currentSession } } = await supabase.auth.getSession()
        session.value = currentSession
        
        if (currentSession) {
          // 直接从session中获取用户信息，避免额外API调用
          user.value = currentSession.user
          
          // 可选：后台获取完整用户资料（不阻塞）
          getUser().then(({ data }) => {
            if (data?.user) {
              user.value = data.user
            }
          }).catch(err => {
            console.error('Background user fetch error:', err)
          })
        }

        // 监听认证状态变化（只创建一次）
        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, newSession) => {
          session.value = newSession
          
          if (newSession) {
            // 直接使用session中的用户信息
            user.value = newSession.user
          } else {
            user.value = null
          }
        })
        
        // 保存监听器引用
        authListener = subscription
      } catch (error) {
        console.error('Initialize user error:', error)
      } finally {
        loading.value = false
      }
    })()

    return initPromise
  }

  /**
   * 设置用户信息
   */
  function setUser(userData) {
    user.value = userData
  }

  /**
   * 登出
   */
  async function logout() {
    try {
      loading.value = true
      
      // 调用API登出
      await apiLogout()
      
      // 立即清空状态
      user.value = null
      session.value = null
      
      // 清除路由权限缓存
      try {
        const { clearPermissionCache } = await import('../router')
        clearPermissionCache()
      } catch (e) {
        console.error('Clear permission cache error:', e)
      }
      
      console.log('Logout successful')
    } catch (error) {
      console.error('Logout error:', error)
      // 即使出错也清空本地状态
      user.value = null
      session.value = null
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 清理监听器
   */
  function cleanup() {
    if (authListener) {
      authListener.unsubscribe()
      authListener = null
      console.log('Auth listener cleaned up')
    }
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    initialize,
    setUser,
    logout,
    cleanup
  }
})
