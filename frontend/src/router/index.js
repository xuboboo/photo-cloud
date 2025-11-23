import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../api/supabase'
import { setPageSEO } from '../utils/seo'

// 使用懒加载优化首屏加载速度
const Home = () => import('../pages/Home.vue')
const Login = () => import('../pages/Login.vue')
const Dashboard = () => import('../pages/Dashboard.vue')
const Upload = () => import('../pages/Upload.vue')
const Preview = () => import('../pages/Preview.vue')
const Admin = () => import('../pages/Admin.vue')
const Settings = () => import('../pages/Settings.vue')
const CreateDocument = () => import('../pages/CreateDocument.vue')
const EditDocument = () => import('../pages/EditDocument.vue')
const Share = () => import('../pages/Share.vue')

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { 
      requiresAuth: false,
      title: '首页',
      description: 'Photo Cloud - 专业的云相册管理系统，安全可靠的云存储服务。支持图片上传、在线预览、文件分享。免费1GB存储，企业级安全保护。',
      keywords: 'Photo Cloud,云相册,云存储,照片管理,图片分享'
    }
  },
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { 
      requiresAuth: false,
      title: '登录',
      description: '登录Photo Cloud云相册，安全访问您的照片和文件。支持邮箱登录，快速注册。',
      keywords: '登录,注册,Photo Cloud,用户登录,账户'
    }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { 
      requiresAuth: true,
      title: '首页',
      description: '安全可靠的云相册管理系统，支持图片上传、在线预览、文件分享。免费1GB存储，企业级安全保护。',
      keywords: 'Photo Cloud,云相册,首页,照片管理,云存储'
    }
  },
  {
    path: '/upload',
    name: 'Upload',
    component: Upload,
    meta: { 
      requiresAuth: true,
      title: '上传文件',
      description: '快速上传照片和文件到云端，支持批量上传、拖拽上传。安全可靠的云存储服务。',
      keywords: '上传文件,上传照片,批量上传,云存储,文件管理'
    }
  },
  {
    path: '/preview/:id',
    name: 'Preview',
    component: Preview,
    meta: { 
      requiresAuth: true,
      title: '文件预览',
      description: '在线预览照片和文件，支持高清预览、下载、分享。',
      keywords: '文件预览,照片预览,在线查看'
    }
  },
  {
    path: '/admin',
    name: 'Admin',
    component: Admin,
    meta: { 
      requiresAuth: true,
      requiresAdmin: true,
      title: '管理后台',
      description: '管理员控制面板，用户管理、系统监控、安全设置。企业级管理功能。',
      keywords: '管理后台,用户管理,系统管理,管理员,控制面板'
    }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: Settings,
    meta: { 
      requiresAuth: true,
      title: '个人设置',
      description: '管理您的账户设置、存储配额、个人信息。查看存储使用情况和账户详情。',
      keywords: '个人设置,账户设置,存储配额,个人资料,用户设置'
    }
  },
  {
    path: '/create',
    name: 'CreateDocument',
    component: CreateDocument,
    meta: { 
      requiresAuth: true,
      title: '创建文档',
      description: '在线创建和编辑Markdown文档，支持实时预览、自动保存。',
      keywords: '创建文档,Markdown,在线编辑'
    }
  },
  {
    path: '/edit/:id',
    name: 'EditDocument',
    component: EditDocument,
    meta: { 
      requiresAuth: true,
      title: '编辑文档',
      description: '编辑Markdown文档，实时预览，云端自动保存。',
      keywords: '编辑文档,Markdown编辑器,在线编辑'
    }
  },
  {
    path: '/share/:token',
    name: 'Share',
    component: Share,
    meta: { 
      requiresAuth: false,
      title: '文件分享',
      description: '查看和下载分享的文件。安全的文件分享服务，支持密码保护和下载限制。',
      keywords: '文件分享,下载文件,分享链接,公开分享'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 权限缓存
const permissionCache = new Map()
const CACHE_DURATION = 5 * 60 * 1000 // 5分钟缓存

// 全局路由守卫 - 登录拦截和权限检查
router.beforeEach(async (to, from, next) => {
  console.log('路由跳转:', from.path, '->', to.path, 'meta:', to.meta)
  
  const requiresAuth = to.meta.requiresAuth !== false
  const requiresAdmin = to.meta.requiresAdmin === true

  if (requiresAuth) {
    // 优先从本地缓存获取session
    const { data: { session } } = await supabase.auth.getSession()
    
    if (!session) {
      next('/login')
      return
    }

    // 检查管理员权限
    if (requiresAdmin) {
      const userId = session.user.id
      const cacheKey = `admin_${userId}`
      const cached = permissionCache.get(cacheKey)
      
      // 检查缓存是否有效
      if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
        if (!cached.isAdmin) {
          console.log('需要管理员权限才能访问此页面')
          next('/dashboard')
          return
        }
        next()
        return
      }
      
      // 缓存失效，查询权限
      try {
        const { data: profile } = await supabase
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .single()
        
        const isAdmin = profile && ['admin', 'super_admin'].includes(profile.role)
        
        // 更新缓存
        permissionCache.set(cacheKey, {
          isAdmin,
          timestamp: Date.now()
        })
        
        if (!isAdmin) {
          console.log('需要管理员权限才能访问此页面')
          next('/dashboard')
          return
        }
      } catch (error) {
        console.error('Check admin permission error:', error)
        next('/dashboard')
        return
      }
    }

    next()
  } else {
    // 如果已登录，访问登录页时重定向到dashboard
    const { data: { session } } = await supabase.auth.getSession()
    
    if (session && to.path === '/login') {
      next('/dashboard')
    } else {
      next()
    }
  }
})

// 路由跳转后更新SEO信息
router.afterEach((to) => {
  // 使用路由meta中的SEO信息
  if (to.meta.title || to.meta.description || to.meta.keywords) {
    setPageSEO({
      title: to.meta.title,
      description: to.meta.description,
      keywords: to.meta.keywords
    })
  }
})

// 清除权限缓存的函数（登出时调用）
export function clearPermissionCache() {
  permissionCache.clear()
}

export default router
