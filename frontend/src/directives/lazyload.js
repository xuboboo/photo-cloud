/**
 * 图片懒加载指令
 * 优化 LCP (Largest Contentful Paint)
 */

export const lazyload = {
  mounted(el, binding) {
    // 检查浏览器是否支持 IntersectionObserver
    if (!('IntersectionObserver' in window)) {
      // 不支持则直接加载
      loadImage(el, binding.value)
      return
    }

    // 创建观察器
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          loadImage(el, binding.value)
          observer.unobserve(el)
        }
      })
    }, {
      rootMargin: '50px', // 提前 50px 开始加载
      threshold: 0.01
    })

    // 开始观察
    observer.observe(el)
    
    // 保存观察器实例以便清理
    el._lazyloadObserver = observer
  },
  
  unmounted(el) {
    // 清理观察器
    if (el._lazyloadObserver) {
      el._lazyloadObserver.disconnect()
      delete el._lazyloadObserver
    }
  }
}

/**
 * 加载图片
 */
function loadImage(el, src) {
  if (!src) return
  
  // 显示加载动画
  el.classList.add('loading')
  
  const img = new Image()
  
  img.onload = () => {
    el.src = src
    el.classList.remove('loading')
    el.classList.add('loaded')
  }
  
  img.onerror = () => {
    el.classList.remove('loading')
    el.classList.add('error')
    // 设置备用图片
    el.src = '/placeholder-error.png'
  }
  
  img.src = src
}

/**
 * 预加载关键图片
 */
export function preloadCriticalImages(urls) {
  urls.forEach(url => {
    const link = document.createElement('link')
    link.rel = 'preload'
    link.as = 'image'
    link.href = url
    document.head.appendChild(link)
  })
}

export default {
  install(app) {
    app.directive('lazyload', lazyload)
  }
}
