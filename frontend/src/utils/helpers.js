/**
 * 格式化文件大小
 */
export function formatFileSize(bytes) {
  if (!bytes || bytes === 0) return '0 B'
  
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
}

/**
 * 格式化日期时间
 */
export function formatDateTime(dateString) {
  if (!dateString) return ''
  
  const date = new Date(dateString)
  const now = new Date()
  const diff = now - date
  
  // 小于 1 分钟
  if (diff < 60000) {
    return '刚刚'
  }
  
  // 小于 1 小时
  if (diff < 3600000) {
    return `${Math.floor(diff / 60000)} 分钟前`
  }
  
  // 小于 24 小时
  if (diff < 86400000) {
    return `${Math.floor(diff / 3600000)} 小时前`
  }
  
  // 小于 7 天
  if (diff < 604800000) {
    return `${Math.floor(diff / 86400000)} 天前`
  }
  
  // 格式化为日期
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

/**
 * 获取文件类型图标
 */
export function getFileIcon(type) {
  const icons = {
    'images': '🖼️',
    'markdown': '📝',
    'image': '🖼️',
    'md': '📝'
  }
  
  return icons[type] || '📄'
}

/**
 * 验证文件类型
 */
export function validateFileType(file, allowedTypes) {
  if (!allowedTypes || allowedTypes.length === 0) return true
  
  return allowedTypes.some(type => {
    if (type.startsWith('.')) {
      return file.name.toLowerCase().endsWith(type)
    }
    return file.type.startsWith(type)
  })
}

/**
 * 验证文件大小
 */
export function validateFileSize(file, maxSize) {
  if (!maxSize) return true
  return file.size <= maxSize
}

/**
 * 复制文本到剪贴板
 */
export async function copyToClipboard(text) {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch (error) {
    console.error('Copy to clipboard error:', error)
    return false
  }
}

/**
 * 防抖函数
 */
export function debounce(fn, delay = 300) {
  let timer = null
  
  return function (...args) {
    if (timer) clearTimeout(timer)
    
    timer = setTimeout(() => {
      fn.apply(this, args)
    }, delay)
  }
}

/**
 * 节流函数
 */
export function throttle(fn, delay = 300) {
  let lastTime = 0
  
  return function (...args) {
    const now = Date.now()
    
    if (now - lastTime >= delay) {
      lastTime = now
      fn.apply(this, args)
    }
  }
}
