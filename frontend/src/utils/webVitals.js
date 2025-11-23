/**
 * Web Vitals 性能监控
 * 监控 LCP, FID, CLS, FCP, TTFB
 */

// 性能指标阈值
const THRESHOLDS = {
  LCP: { good: 2500, poor: 4000 },      // Largest Contentful Paint
  FID: { good: 100, poor: 300 },        // First Input Delay
  CLS: { good: 0.1, poor: 0.25 },       // Cumulative Layout Shift
  FCP: { good: 1800, poor: 3000 },      // First Contentful Paint
  TTFB: { good: 800, poor: 1800 }       // Time to First Byte
}

/**
 * 获取性能等级
 */
function getPerformanceGrade(metric, value) {
  if (value <= THRESHOLDS[metric].good) return 'good'
  if (value <= THRESHOLDS[metric].poor) return 'needs-improvement'
  return 'poor'
}

/**
 * 报告性能指标
 */
function reportMetric(metric) {
  const grade = getPerformanceGrade(metric.name, metric.value)
  
  console.log(`[Web Vitals] ${metric.name}: ${metric.value.toFixed(2)}ms (${grade})`)
  
  // 可以发送到分析服务
  if (window.gtag) {
    window.gtag('event', metric.name, {
      value: Math.round(metric.value),
      metric_id: metric.id,
      metric_value: metric.value,
      metric_delta: metric.delta,
      metric_grade: grade
    })
  }
}

/**
 * 监控 LCP (Largest Contentful Paint)
 */
export function observeLCP() {
  if (!('PerformanceObserver' in window)) return

  try {
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries()
      const lastEntry = entries[entries.length - 1]
      
      reportMetric({
        name: 'LCP',
        value: lastEntry.renderTime || lastEntry.loadTime,
        id: generateUniqueId()
      })
    })

    observer.observe({ entryTypes: ['largest-contentful-paint'] })
  } catch (e) {
    console.error('LCP observation error:', e)
  }
}

/**
 * 监控 FID (First Input Delay)
 */
export function observeFID() {
  if (!('PerformanceObserver' in window)) return

  try {
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries()
      
      entries.forEach(entry => {
        reportMetric({
          name: 'FID',
          value: entry.processingStart - entry.startTime,
          id: generateUniqueId()
        })
      })
    })

    observer.observe({ entryTypes: ['first-input'] })
  } catch (e) {
    console.error('FID observation error:', e)
  }
}

/**
 * 监控 CLS (Cumulative Layout Shift)
 */
export function observeCLS() {
  if (!('PerformanceObserver' in window)) return

  let clsValue = 0
  let clsEntries = []

  try {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        // 只统计没有用户交互的布局偏移
        if (!entry.hadRecentInput) {
          clsValue += entry.value
          clsEntries.push(entry)
        }
      }
    })

    observer.observe({ entryTypes: ['layout-shift'] })

    // 页面卸载时报告
    window.addEventListener('beforeunload', () => {
      reportMetric({
        name: 'CLS',
        value: clsValue,
        id: generateUniqueId()
      })
    }, { once: true })
  } catch (e) {
    console.error('CLS observation error:', e)
  }
}

/**
 * 监控 FCP (First Contentful Paint)
 */
export function observeFCP() {
  try {
    const paintEntries = performance.getEntriesByType('paint')
    const fcpEntry = paintEntries.find(entry => entry.name === 'first-contentful-paint')
    
    if (fcpEntry) {
      reportMetric({
        name: 'FCP',
        value: fcpEntry.startTime,
        id: generateUniqueId()
      })
    }
  } catch (e) {
    console.error('FCP observation error:', e)
  }
}

/**
 * 监控 TTFB (Time to First Byte)
 */
export function observeTTFB() {
  try {
    const navigationTiming = performance.getEntriesByType('navigation')[0]
    
    if (navigationTiming) {
      const ttfb = navigationTiming.responseStart - navigationTiming.requestStart
      
      reportMetric({
        name: 'TTFB',
        value: ttfb,
        id: generateUniqueId()
      })
    }
  } catch (e) {
    console.error('TTFB observation error:', e)
  }
}

/**
 * 初始化所有性能监控
 */
export function initWebVitals() {
  if (typeof window === 'undefined') return

  // 等待页面加载完成
  if (document.readyState === 'complete') {
    startObserving()
  } else {
    window.addEventListener('load', startObserving)
  }
}

/**
 * 开始监控
 */
function startObserving() {
  observeLCP()
  observeFID()
  observeCLS()
  observeFCP()
  observeTTFB()
}

/**
 * 生成唯一 ID
 */
function generateUniqueId() {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

/**
 * 获取性能总结
 */
export function getPerformanceSummary() {
  const navigation = performance.getEntriesByType('navigation')[0]
  const paint = performance.getEntriesByType('paint')
  
  return {
    // 导航时间
    domContentLoaded: navigation?.domContentLoadedEventEnd - navigation?.domContentLoadedEventStart,
    loadComplete: navigation?.loadEventEnd - navigation?.loadEventStart,
    
    // 绘制时间
    firstPaint: paint.find(entry => entry.name === 'first-paint')?.startTime,
    firstContentfulPaint: paint.find(entry => entry.name === 'first-contentful-paint')?.startTime,
    
    // 资源统计
    resourceCount: performance.getEntriesByType('resource').length,
    
    // 内存使用（如果支持）
    memory: performance.memory ? {
      usedJSHeapSize: (performance.memory.usedJSHeapSize / 1048576).toFixed(2) + ' MB',
      totalJSHeapSize: (performance.memory.totalJSHeapSize / 1048576).toFixed(2) + ' MB'
    } : null
  }
}

export default {
  install(app) {
    // 自动初始化
    if (process.env.NODE_ENV === 'production') {
      initWebVitals()
    }
    
    // 提供全局访问
    app.config.globalProperties.$webVitals = {
      init: initWebVitals,
      getSummary: getPerformanceSummary
    }
  }
}
