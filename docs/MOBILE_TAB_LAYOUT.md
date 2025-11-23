# 📱 移动端 Tab 布局统一方案

## 概述

所有页面在移动端都使用统一的 Tab 布局，提供类似原生 App 的体验。

## 布局组件

### MobileLayout.vue
统一的移动端布局包装组件，提供：
- 顶部标题栏
- 内容区域
- 底部 Tab 导航栏

## 页面适配情况

### ✅ 已适配页面

#### 1. Dashboard (首页)
- **移动端**：完整 Tab 布局
- **桌面端**：传统布局
- **Tab 位置**：🏠 文件（激活）

#### 2. Upload (上传)
- **移动端**：使用 MobileLayout
- **桌面端**：传统布局
- **Tab 位置**：📤 上传（激活）
- **特点**：显示返回按钮

#### 3. Settings (我的)
- **移动端**：使用 MobileLayout
- **桌面端**：传统布局
- **Tab 位置**：👤 我的（激活）
- **特点**：无返回按钮

#### 4. CreateDocument (新建文档)
- **移动端**：使用 MobileLayout
- **桌面端**：传统布局
- **特点**：显示返回按钮

### 🔄 需要适配的页面

#### EditDocument (编辑文档)
- 当前状态：桌面端布局
- 建议：添加 MobileLayout

#### Preview (预览)
- 当前状态：桌面端布局
- 建议：添加 MobileLayout

#### Admin (管理后台)
- 当前状态：桌面端布局
- 建议：保持桌面端布局（管理功能）

#### Share (分享页面)
- 当前状态：独立布局
- 建议：保持独立布局（公开访问）

## Tab 导航栏

### Tab 配置
```javascript
const tabs = [
  { id: 'home', icon: '🏠', label: '文件', path: '/' },
  { id: 'upload', icon: '📤', label: '上传', path: '/upload' },
  { id: 'stats', icon: '📊', label: '用量', path: '/settings' },
  { id: 'profile', icon: '👤', label: '我的', path: '/settings' }
]
```

### 激活状态
- 根据当前路由自动高亮
- 点击切换页面
- 平滑过渡动画

## 使用方法

### 基本用法
```vue
<template>
  <MobileLayout title="页面标题" :show-back="false">
    <!-- 移动端内容 -->
    <div class="mobile-content">
      <!-- 你的内容 -->
    </div>
    
    <!-- 桌面端内容（可选） -->
    <template #desktop>
      <div class="desktop-content">
        <!-- 桌面端布局 -->
      </div>
    </template>
  </MobileLayout>
</template>

<script setup>
import MobileLayout from '../layouts/MobileLayout.vue'
</script>
```

### Props

#### title
- 类型：`String`
- 默认值：`'文件管理'`
- 说明：顶部标题栏显示的文字

#### showBack
- 类型：`Boolean`
- 默认值：`false`
- 说明：是否显示返回按钮

### Slots

#### default
- 移动端和桌面端共用的内容
- 在移动端显示在内容区域
- 在桌面端也会显示（如果没有 desktop slot）

#### desktop
- 仅桌面端显示的内容
- 如果提供，移动端不会显示 default slot

## 布局结构

### 移动端 (<768px)
```
┌─────────────────────────────────┐
│ [返回] 页面标题    [退出登录]   │ ← 顶部栏
├─────────────────────────────────┤
│                                 │
│                                 │
│         内容区域                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│ 🏠   📤   📊   👤              │ ← Tab 栏
│ 文件  上传  用量  我的           │
└─────────────────────────────────┘
```

### 桌面端 (>768px)
```
传统布局（顶部导航 + 内容区域）
```

## 样式特点

### 顶部栏
- 固定定位
- 白色背景
- 底部阴影
- 安全区域适配

### 内容区域
- 可滚动
- 灰色背景
- 底部留白（避免被 Tab 遮挡）

### Tab 栏
- 固定在底部
- 毛玻璃效果
- 4 个 Tab 均分
- 活动状态高亮

### 退出按钮
- 红色渐变背景
- 深红色文字
- 圆角设计
- 点击缩放动画

## 响应式行为

### 断点：768px
- `<768px`：显示移动端布局
- `>=768px`：显示桌面端布局

### 自动切换
- 窗口大小改变时自动切换
- 横屏/竖屏自动适配
- 保持状态不丢失

## 性能优化

### 条件渲染
- 使用 `v-if` 而非 `v-show`
- 只渲染当前需要的布局
- 减少 DOM 节点

### 懒加载
- 内容区域支持懒加载
- 图片按需加载
- 优化首屏速度

## 最佳实践

### 1. 标题设置
```vue
<MobileLayout title="清晰的页面标题">
```
- 使用简短清晰的标题
- 不超过 10 个字符
- 描述页面主要功能

### 2. 返回按钮
```vue
<MobileLayout :show-back="true">
```
- 二级页面显示返回按钮
- 一级页面（Tab 页）不显示
- 返回到上一页

### 3. 内容区域
```vue
<div class="mobile-content">
  <div class="content-padding">
    <!-- 内容 -->
  </div>
</div>
```
- 添加适当的内边距
- 考虑底部 Tab 栏高度
- 使用 `padding-bottom: calc(70px + env(safe-area-inset-bottom))`

### 4. 桌面端适配
```vue
<template #desktop>
  <!-- 完整的桌面端布局 -->
</template>
```
- 提供完整的桌面端体验
- 不要简单复制移动端布局
- 利用更大的屏幕空间

## 注意事项

### 1. 路由配置
- 确保路由路径正确
- Tab 激活状态依赖路由
- 使用 `router.push()` 导航

### 2. 状态管理
- 页面切换保持状态
- 使用 Pinia 或 localStorage
- 避免数据丢失

### 3. 安全区域
- 支持刘海屏
- 使用 `env(safe-area-inset-*)`
- 测试不同设备

### 4. 性能
- 避免过度渲染
- 使用虚拟滚动（大列表）
- 优化图片加载

## 未来改进

### 计划功能
- [ ] Tab 徽章（未读数量）
- [ ] 手势导航（左右滑动）
- [ ] 页面转场动画
- [ ] 下拉刷新
- [ ] 上拉加载更多

### 优化方向
- [ ] 更流畅的动画
- [ ] 更好的触摸反馈
- [ ] 离线支持
- [ ] PWA 功能

## 更新日志

### v1.0.0 (2024-01-20)
- ✅ 创建 MobileLayout 组件
- ✅ 适配 Dashboard 页面
- ✅ 适配 Upload 页面
- ✅ 适配 Settings 页面
- ✅ 适配 CreateDocument 页面
- ✅ 统一 Tab 导航栏
- ✅ 统一顶部标题栏
