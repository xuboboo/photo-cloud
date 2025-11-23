/**
 * SEO工具函数
 * 用于动态设置页面meta标签
 */

/**
 * 设置页面标题
 */
export function setPageTitle(title) {
  document.title = title ? `${title} - Photo Cloud` : 'Photo Cloud - 专业云相册管理系统'
}

/**
 * 设置meta标签
 */
export function setMetaTag(name, content) {
  let meta = document.querySelector(`meta[name="${name}"]`)
  if (!meta) {
    meta = document.createElement('meta')
    meta.setAttribute('name', name)
    document.head.appendChild(meta)
  }
  meta.setAttribute('content', content)
}

/**
 * 设置Open Graph标签
 */
export function setOgTag(property, content) {
  let meta = document.querySelector(`meta[property="${property}"]`)
  if (!meta) {
    meta = document.createElement('meta')
    meta.setAttribute('property', property)
    document.head.appendChild(meta)
  }
  meta.setAttribute('content', content)
}

/**
 * 设置页面SEO信息
 */
export function setPageSEO({ title, description, keywords, ogImage }) {
  // 设置标题
  if (title) {
    setPageTitle(title)
  }
  
  // 设置描述
  if (description) {
    setMetaTag('description', description)
    setOgTag('og:description', description)
  }
  
  // 设置关键词
  if (keywords) {
    setMetaTag('keywords', keywords)
  }
  
  // 设置OG标签
  if (title) {
    setOgTag('og:title', `${title} - Photo Cloud`)
  }
  
  setOgTag('og:type', 'website')
  setOgTag('og:url', window.location.href)
  
  if (ogImage) {
    setOgTag('og:image', ogImage)
  }
}

/**
 * 重置为默认SEO
 */
export function resetPageSEO() {
  setPageSEO({
    title: '专业云相册管理系统',
    description: 'Photo Cloud - 专业的云相册管理系统，安全可靠的云存储服务。支持图片上传、在线预览、文件分享、智能管理。免费1GB存储空间，企业级数据安全保护，多端同步。',
    keywords: 'Photo Cloud,云相册,云存储,照片管理,图片分享,文件管理'
  })
}

/**
 * 页面SEO配置
 */
export const pageSEO = {
  home: {
    title: '首页',
    description: '安全可靠的云相册管理系统，支持图片上传、在线预览、文件分享。免费1GB存储，企业级安全保护。',
    keywords: 'Photo Cloud,云相册,首页,照片管理,云存储'
  },
  
  login: {
    title: '登录',
    description: '登录Photo Cloud云相册，安全访问您的照片和文件。支持邮箱登录，快速注册。',
    keywords: '登录,注册,Photo Cloud,用户登录,账户'
  },
  
  upload: {
    title: '上传文件',
    description: '快速上传照片和文件到云端，支持批量上传、拖拽上传。安全可靠的云存储服务。',
    keywords: '上传文件,上传照片,批量上传,云存储,文件管理'
  },
  
  files: {
    title: '我的文件',
    description: '管理您的所有照片和文件，支持文件夹组织、快速搜索、批量操作。',
    keywords: '我的文件,文件管理,照片管理,文件夹,云存储'
  },
  
  share: {
    title: '分享管理',
    description: '管理您的文件分享，支持密码保护、有效期设置、下载限制。安全便捷的文件分享。',
    keywords: '文件分享,分享管理,密码保护,分享链接,安全分享'
  },
  
  settings: {
    title: '个人设置',
    description: '管理您的账户设置、存储配额、个人信息。查看存储使用情况和账户详情。',
    keywords: '个人设置,账户设置,存储配额,个人资料,用户设置'
  },
  
  admin: {
    title: '管理后台',
    description: '管理员控制面板，用户管理、系统监控、安全设置。企业级管理功能。',
    keywords: '管理后台,用户管理,系统管理,管理员,控制面板'
  },
  
  publicShare: {
    title: '文件分享',
    description: '查看和下载分享的文件。安全的文件分享服务，支持密码保护和下载限制。',
    keywords: '文件分享,下载文件,分享链接,公开分享'
  }
}
