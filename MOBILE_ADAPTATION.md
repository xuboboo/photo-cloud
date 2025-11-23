# 📱 移动端适配指南

## 支持的设备

### 📱 手机设备
- **小屏手机** (320px - 374px)
  - iPhone SE (1st gen)
  - 小型 Android 设备
  
- **标准手机** (375px - 639px)
  - iPhone 12/13/14
  - iPhone 12/13/14 Pro
  - 大部分 Android 手机
  
- **大屏手机** (640px - 767px)
  - iPhone 12/13/14 Pro Max
  - iPhone 14 Plus
  - 大屏 Android 手机

### 📱 平板设备
- **小平板** (768px - 1023px)
  - iPad
  - iPad Air
  - Android 平板
  
- **大平板** (1024px+)
  - iPad Pro 11"
  - iPad Pro 12.9"

### 💻 桌面设备
- **笔记本** (1024px - 1439px)
- **桌面显示器** (1440px - 1919px)
- **大屏显示器** (1920px+)

## 响应式断点

```css
/* 小屏手机 */
@media (max-width: 374px) { }

/* 标准手机 */
@media (min-width: 375px) and (max-width: 639px) { }

/* 大屏手机 */
@media (min-width: 640px) and (max-width: 767px) { }

/* 平板 */
@media (min-width: 768px) and (max-width: 1023px) { }

/* 笔记本 */
@media (min-width: 1024px) and (max-width: 1439px) { }

/* 桌面 */
@media (min-width: 1440px) { }
```

## 移动端优化特性

### 1. 视口设置
- ✅ 正确的 viewport meta 标签
- ✅ 支持用户缩放（最大 5 倍）
- ✅ viewport-fit=cover（支持刘海屏）

### 2. 触摸优化
- ✅ 最小触摸目标 44px (iOS) / 48px (Android)
- ✅ 触摸反馈动画
- ✅ 防止误触（tap-highlight）
- ✅ 平滑滚动

### 3. 安全区域适配
- ✅ 支持刘海屏（iPhone X 及以后）
- ✅ 支持全面屏
- ✅ 自动适配 safe-area-inset

### 4. 性能优化
- ✅ 硬件加速
- ✅ 防抖处理
- ✅ 懒加载图片
- ✅ 虚拟滚动（大列表）

### 5. 交互优化
- ✅ 底部 Tab 导航
- ✅ 大按钮和图标
- ✅ 清晰的视觉反馈
- ✅ 手势支持

### 6. 字体优化
- ✅ 16px 基础字体（防止 iOS 自动缩放）
- ✅ 响应式字体大小
- ✅ 抗锯齿渲染

### 7. 横屏支持
- ✅ 自动适配横屏布局
- ✅ 优化的导航栏高度
- ✅ 合理的内容排版

## 特殊设备适配

### iPhone 刘海屏系列
- iPhone X, XS, 11 Pro (375x812)
- iPhone XR, XS Max, 11, 11 Pro Max (414x896)
- iPhone 12, 12 Pro, 13, 13 Pro, 14 (390x844)
- iPhone 12 Pro Max, 13 Pro Max, 14 Plus (428x926)
- iPhone 14 Pro (393x852)

### iPad 系列
- iPad (768x1024)
- iPad Pro 11" (834x1194)
- iPad Pro 12.9" (1024x1366)

## 使用设备检测工具

```javascript
import { device, getDeviceInfo } from '@/utils/device'

// 检测设备类型
if (device.isMobile) {
  console.log('移动设备')
}

if (device.isIOS) {
  console.log('iOS 设备')
}

// 获取完整设备信息
const info = getDeviceInfo()
console.log(info)
```

## 视口高度问题解决

移动端 100vh 包含地址栏高度，导致内容被遮挡。使用 CSS 变量解决：

```css
.full-height {
  height: 100vh;
  height: calc(var(--vh, 1vh) * 100);
}
```

## 测试建议

### 真机测试
- iPhone SE (小屏)
- iPhone 12/13/14 (标准)
- iPhone 14 Pro Max (大屏)
- iPad (平板)
- Android 手机

### 浏览器测试
- Chrome DevTools (设备模拟)
- Safari 响应式设计模式
- Firefox 响应式设计模式

### 测试要点
- [ ] 触摸目标大小
- [ ] 文字可读性
- [ ] 图片加载
- [ ] 滚动性能
- [ ] 横屏显示
- [ ] 安全区域
- [ ] 下载功能
- [ ] 表单输入

## 性能指标

### 目标
- First Contentful Paint (FCP) < 1.8s
- Largest Contentful Paint (LCP) < 2.5s
- Time to Interactive (TTI) < 3.8s
- Cumulative Layout Shift (CLS) < 0.1

### 优化措施
- 图片懒加载
- 代码分割
- 资源压缩
- CDN 加速
- 缓存策略

## 常见问题

### Q: iOS 输入框被键盘遮挡？
A: 使用 `scrollIntoView()` 或监听 `focus` 事件调整滚动位置。

### Q: Android 返回键不工作？
A: 监听 `popstate` 事件处理浏览器返回。

### Q: 图片在移动端加载慢？
A: 使用响应式图片和懒加载。

### Q: 横屏布局错乱？
A: 使用 `orientation` 媒体查询单独处理。

## 更新日志

### v1.0.0 (2024-01-20)
- ✅ 完整的响应式断点系统
- ✅ 移动端触摸优化
- ✅ 安全区域适配
- ✅ 设备检测工具
- ✅ 视口高度修复
- ✅ 下载功能优化
