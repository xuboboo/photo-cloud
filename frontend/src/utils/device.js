/**
 * 设备检测和适配工具
 */

// 获取用户代理
const ua = navigator.userAgent

/**
 * 检测设备类型
 */
export const device = {
  // 移动设备
  isMobile: /iPhone|iPad|iPod|Android|Mobile/i.test(ua),
  
  // iOS 设备
  isIOS: /iPhone|iPad|iPod/i.test(ua),
  isIPhone: /iPhone/i.test(ua),
  isIPad: /iPad/i.test(ua),
  
  // Android 设备
  isAndroid: /Android/i.test(ua),
  
  // 平板
  isTablet: /iPad|Android(?!.*Mobile)/i.test(ua),
  
  // 桌面
  isDesktop: !/iPhone|iPad|iPod|Android|Mobile/i.test(ua),
  
  // 浏览器
  isChrome: /Chrome/i.test(ua) && !/Edge/i.test(ua),
  isSafari: /Safari/i.test(ua) && !/Chrome/i.test(ua),
  isFirefox: /Firefox/i.test(ua),
  isEdge: /Edge/i.test(ua),
  
  // 微信浏览器
  isWeChat: /MicroMessenger/i.test(ua),
  
  // 触摸支持
  hasTouch: 'ontouchstart' in window || navigator.maxTouchPoints > 0
}

/**
 * 获取屏幕尺寸信息
 */
export function getScreenInfo() {
  return {
    width: window.innerWidth,
    height: window.innerHeight,
    devicePixelRatio: window.devicePixelRatio || 1,
    orientation: window.innerWidth > window.innerHeight ? 'landscape' : 'portrait'
  }
}

/**
 * 获取设备类别
 */
export function getDeviceCategory() {
  const width = window.innerWidth
  
  if (width < 375) return 'small-phone'      // 小屏手机
  if (width < 640) return 'phone'            // 标准手机
  if (width < 768) return 'large-phone'      // 大屏手机
  if (width < 1024) return 'tablet'          // 平板
  if (width < 1440) return 'laptop'          // 笔记本
  if (width < 1920) return 'desktop'         // 桌面
  return 'large-desktop'                     // 大屏桌面
}

/**
 * 检测是否为刘海屏/全面屏
 */
export function hasNotch() {
  if (!device.isIOS) return false
  
  const screenHeight = window.screen.height
  const screenWidth = window.screen.width
  
  // iPhone X 及以后的设备
  const notchDevices = [
    { width: 375, height: 812 },  // iPhone X, XS, 11 Pro, 12 mini, 13 mini
    { width: 414, height: 896 },  // iPhone XR, XS Max, 11, 11 Pro Max
    { width: 390, height: 844 },  // iPhone 12, 12 Pro, 13, 13 Pro, 14
    { width: 428, height: 926 },  // iPhone 12 Pro Max, 13 Pro Max, 14 Plus, 14 Pro Max
    { width: 393, height: 852 },  // iPhone 14 Pro
  ]
  
  return notchDevices.some(d => 
    (d.width === screenWidth && d.height === screenHeight) ||
    (d.width === screenHeight && d.height === screenWidth)
  )
}

/**
 * 获取安全区域 insets
 */
export function getSafeAreaInsets() {
  const style = getComputedStyle(document.documentElement)
  
  return {
    top: parseInt(style.getPropertyValue('env(safe-area-inset-top)')) || 0,
    right: parseInt(style.getPropertyValue('env(safe-area-inset-right)')) || 0,
    bottom: parseInt(style.getPropertyValue('env(safe-area-inset-bottom)')) || 0,
    left: parseInt(style.getPropertyValue('env(safe-area-inset-left)')) || 0
  }
}

/**
 * 监听屏幕方向变化
 */
export function onOrientationChange(callback) {
  const handleChange = () => {
    const info = getScreenInfo()
    callback(info.orientation, info)
  }
  
  window.addEventListener('orientationchange', handleChange)
  window.addEventListener('resize', handleChange)
  
  // 返回清理函数
  return () => {
    window.removeEventListener('orientationchange', handleChange)
    window.removeEventListener('resize', handleChange)
  }
}

/**
 * 监听屏幕尺寸变化
 */
export function onResize(callback) {
  let timeoutId = null
  
  const handleResize = () => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      callback(getScreenInfo())
    }, 150)
  }
  
  window.addEventListener('resize', handleResize)
  
  return () => {
    clearTimeout(timeoutId)
    window.removeEventListener('resize', handleResize)
  }
}

/**
 * 设置视口高度 CSS 变量（解决移动端 100vh 问题）
 */
export function setViewportHeight() {
  const vh = window.innerHeight * 0.01
  document.documentElement.style.setProperty('--vh', `${vh}px`)
}

// 初始化视口高度
setViewportHeight()

// 监听窗口大小变化
window.addEventListener('resize', setViewportHeight)
window.addEventListener('orientationchange', setViewportHeight)

/**
 * 获取设备信息摘要
 */
export function getDeviceInfo() {
  return {
    ...device,
    category: getDeviceCategory(),
    screen: getScreenInfo(),
    hasNotch: hasNotch(),
    safeArea: getSafeAreaInsets()
  }
}

// 导出默认对象
export default {
  device,
  getScreenInfo,
  getDeviceCategory,
  hasNotch,
  getSafeAreaInsets,
  onOrientationChange,
  onResize,
  setViewportHeight,
  getDeviceInfo
}
