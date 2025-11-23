# 开发指南

本文档为开发者提供详细的开发指南和最佳实践。

## 🛠️ 开发环境设置

### 必需工具

- Node.js 18+ 
- npm 或 yarn
- Git
- 代码编辑器（推荐 VS Code）

### VS Code 推荐扩展

- Vue Language Features (Volar)
- ESLint
- Prettier
- GitLens
- Auto Rename Tag
- Path Intellisense

## 📁 项目结构详解

### 前端架构

```
frontend/src/
├── api/                    # API 层
│   ├── supabase.js        # Supabase 客户端初始化
│   ├── auth.js            # 认证相关 API
│   └── files.js           # 文件操作 API
│
├── components/            # 可复用组件
│   ├── FileUploader.vue   # 文件上传组件（支持拖拽）
│   ├── FileList.vue       # 文件列表组件
│   └── MarkdownViewer.vue # Markdown 预览组件
│
├── pages/                 # 页面组件
│   ├── Login.vue          # 登录/注册页
│   ├── Dashboard.vue      # 主控制台
│   ├── Upload.vue         # 上传页面
│   └── Preview.vue        # 预览页面
│
├── router/                # 路由配置
│   └── index.js           # 路由定义和守卫
│
├── stores/                # 状态管理
│   └── user.js            # 用户状态（Pinia）
│
├── utils/                 # 工具函数
│   ├── helpers.js         # 通用辅助函数
│   └── markdown.js        # Markdown 渲染工具
│
├── App.vue                # 根组件
├── main.js                # 应用入口
└── style.css              # 全局样式
```

### 后端架构

```
backend/
├── sql/                   # 数据库脚本
│   ├── 01_tables.sql      # 表结构定义
│   ├── 02_rls.sql         # 行级安全策略
│   └── 03_seed.sql        # 种子数据
│
└── storage-rules/         # Storage 配置
    └── private-files.json # Bucket 权限配置
```

## 🔧 核心功能实现

### 1. 认证流程

```javascript
// 登录
const { user } = await login(email, password)
userStore.setUser(user)
router.push('/')

// 注册
const { user } = await register(email, password)
// 可能需要邮箱验证

// 登出
await userStore.logout()
router.push('/login')
```

### 2. 文件上传流程

```javascript
// 1. 选择文件
const file = event.target.files[0]

// 2. 验证文件
validateFileSize(file, maxSize)
validateFileType(file, allowedTypes)

// 3. 上传到 Storage
const filePath = `${type}/${userId}/${timestamp}-${fileName}`
await supabase.storage.from('private-files').upload(filePath, file)

// 4. 记录到数据库
await supabase.from('files').insert({
  user_id: userId,
  path: filePath,
  name: fileName,
  type: type,
  size: fileSize
})
```

### 3. 文件访问流程

```javascript
// 1. 获取文件信息
const file = await getFileById(fileId)

// 2. 生成签名 URL
const signedUrl = await getSignedUrl(file.path, 3600)

// 3. 访问文件
window.open(signedUrl) // 下载
// 或
const response = await axios.get(signedUrl) // 预览
```

## 🎨 样式规范

### CSS 命名约定

使用 BEM 命名法：

```css
/* Block */
.file-uploader { }

/* Element */
.file-uploader__input { }

/* Modifier */
.file-uploader--disabled { }
```

### 颜色系统

```css
/* 主色调 */
--primary: #4299e1;
--primary-dark: #3182ce;

/* 语义色 */
--success: #48bb78;
--warning: #ed8936;
--error: #e53e3e;

/* 中性色 */
--gray-50: #f7fafc;
--gray-100: #edf2f7;
--gray-200: #e2e8f0;
--gray-300: #cbd5e0;
--gray-400: #a0aec0;
--gray-500: #718096;
--gray-600: #4a5568;
--gray-700: #2d3748;
--gray-800: #1a202c;
```

## 🔐 安全最佳实践

### 1. 前端安全

```javascript
// ✅ 好的做法
const url = import.meta.env.VITE_SUPABASE_URL

// ❌ 不好的做法
const url = 'https://hardcoded-url.supabase.co'
```

### 2. 数据验证

```javascript
// 始终在前端验证
if (!validateFileSize(file, MAX_SIZE)) {
  throw new Error('文件太大')
}

// 后端（Supabase）也会验证
// - RLS 策略
// - Storage 规则
// - 数据库约束
```

### 3. 错误处理

```javascript
try {
  await uploadFile(file, type)
} catch (error) {
  // 记录错误
  console.error('Upload error:', error)
  
  // 显示用户友好的错误信息
  showError('上传失败，请重试')
  
  // 可选：发送到错误追踪服务
  // Sentry.captureException(error)
}
```

## 🧪 测试策略

### 单元测试

```javascript
// 测试工具函数
import { formatFileSize } from '@/utils/helpers'

describe('formatFileSize', () => {
  it('should format bytes correctly', () => {
    expect(formatFileSize(1024)).toBe('1 KB')
    expect(formatFileSize(1048576)).toBe('1 MB')
  })
})
```

### 组件测试

```javascript
// 测试 Vue 组件
import { mount } from '@vue/test-utils'
import FileUploader from '@/components/FileUploader.vue'

describe('FileUploader', () => {
  it('should emit upload-success event', async () => {
    const wrapper = mount(FileUploader)
    // ... 测试逻辑
  })
})
```

## 📊 性能优化

### 1. 代码分割

```javascript
// 路由懒加载
const Dashboard = () => import('./pages/Dashboard.vue')
```

### 2. 图片优化

```javascript
// 压缩图片
const compressImage = async (file) => {
  // 使用 canvas 或第三方库压缩
}
```

### 3. 缓存策略

```javascript
// 缓存文件列表
const cachedFiles = ref([])
const cacheTime = 5 * 60 * 1000 // 5 分钟

if (Date.now() - lastFetchTime < cacheTime) {
  return cachedFiles.value
}
```

## 🐛 调试技巧

### 1. Vue DevTools

安装 Vue DevTools 浏览器扩展，可以：
- 查看组件树
- 检查 Pinia 状态
- 追踪事件
- 性能分析

### 2. Supabase 日志

在 Supabase Dashboard 中查看：
- API 请求日志
- 数据库查询
- Storage 操作
- 认证事件

### 3. 网络调试

```javascript
// 在 API 调用中添加日志
export async function uploadFile(file, type) {
  console.log('Uploading file:', { name: file.name, size: file.size, type })
  
  const result = await supabase.storage.from('private-files').upload(...)
  
  console.log('Upload result:', result)
  
  return result
}
```

## 🔄 Git 工作流

### 分支策略

```bash
main          # 生产环境
├── develop   # 开发环境
    ├── feature/upload-ui      # 功能分支
    ├── feature/markdown-preview
    └── bugfix/login-error     # 修复分支
```

### 提交规范

```bash
# 功能
git commit -m "feat: add drag and drop upload"

# 修复
git commit -m "fix: resolve login redirect issue"

# 文档
git commit -m "docs: update API documentation"

# 样式
git commit -m "style: improve button hover effects"

# 重构
git commit -m "refactor: simplify file upload logic"
```

## 📝 代码审查清单

提交 PR 前检查：

- [ ] 代码符合项目规范
- [ ] 添加了必要的注释
- [ ] 没有 console.log 调试代码
- [ ] 错误处理完善
- [ ] 组件可复用性良好
- [ ] 性能优化考虑
- [ ] 响应式设计适配
- [ ] 无安全隐患
- [ ] 测试通过

## 🚀 新功能开发流程

1. **需求分析**
   - 明确功能需求
   - 设计 UI/UX
   - 评估技术方案

2. **数据库设计**
   - 设计表结构
   - 编写 SQL 脚本
   - 配置 RLS 策略

3. **API 开发**
   - 实现 API 函数
   - 添加错误处理
   - 编写文档

4. **组件开发**
   - 创建 Vue 组件
   - 实现业务逻辑
   - 添加样式

5. **集成测试**
   - 功能测试
   - 边界测试
   - 性能测试

6. **代码审查**
   - 自我审查
   - 团队审查
   - 修改优化

7. **部署上线**
   - 合并到主分支
   - 部署到生产环境
   - 监控运行状态

## 📚 学习资源

### Vue 3
- [Vue 3 官方文档](https://vuejs.org/)
- [Vue Router 文档](https://router.vuejs.org/)
- [Pinia 文档](https://pinia.vuejs.org/)

### Supabase
- [Supabase 文档](https://supabase.com/docs)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### 工具
- [Vite 文档](https://vitejs.dev/)
- [Markdown-it 文档](https://markdown-it.github.io/)
- [Axios 文档](https://axios-http.com/)

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📞 获取帮助

- 查看文档
- 搜索已有 Issue
- 创建新 Issue
- 加入社区讨论
