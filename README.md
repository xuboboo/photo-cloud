# Photo Cloud - 专业云相册管理系统

<div align="center">

![Photo Cloud](https://img.shields.io/badge/Photo%20Cloud-v1.0.0-blue)
![Vue 3](https://img.shields.io/badge/Vue-3.3.11-4FC08D?logo=vue.js)
![Supabase](https://img.shields.io/badge/Supabase-Latest-3ECF8E?logo=supabase)
![Cloudflare](https://img.shields.io/badge/Cloudflare-Workers-F38020?logo=cloudflare)
![License](https://img.shields.io/badge/license-MIT-green)

**基于 Vue 3 + Supabase + Cloudflare Workers 的现代化云相册管理系统**

[在线演示](https://www.tournews.top) · [快速开始](#-快速开始) · [文档中心](./docs)

</div>

---

## ✨ 功能特性

### 核心功能
- 🔐 **用户认证系统** - 注册/登录、邮箱验证、密码管理
- 📤 **文件上传** - 支持拖拽、批量上传、进度显示
- 🖼️ **图片管理** - 高清预览、相册管理、缩略图
- 📝 **Markdown 编辑器** - 在线创建、实时预览、云端保存
- 🔗 **文件分享** - 一键生成分享链接、密码保护、有效期设置
- 📁 **文件夹管理** - 创建文件夹、文件分类、树形结构

### 高级功能
- 👑 **管理员后台** - 用户管理、存储配额、系统监控
- 🔒 **企业级安全** - RLS 策略、数据隔离、黑名单系统
- 📱 **移动端适配** - 响应式设计、手势支持、PWA
- ⚡ **性能优化** - 懒加载、缓存策略、CDN 加速
- 📊 **数据统计** - 存储使用、活动日志、下载追踪
- 🌐 **SEO 优化** - 动态 meta、sitemap、搜索引擎友好

## 🏗️ 技术栈

### 前端
- Vue 3 - 渐进式 JavaScript 框架
- Vue Router - 官方路由管理器
- Pinia - 状态管理
- Vite - 下一代前端构建工具
- Axios - HTTP 客户端
- Markdown-it - Markdown 渲染器

### 后端 & 基础设施
- **Supabase** - 开源 Firebase 替代方案
  - PostgreSQL 数据库
  - 用户认证系统
  - Storage 文件存储
  - 行级安全策略（RLS）
  - 实时订阅
  - Edge Functions
  
- **Cloudflare Workers** - 边缘计算平台
  - 全球 CDN 分发
  - SPA 路由支持
  - 可观测性监控
  - 零冷启动

### 开发工具
- **Wrangler** - Cloudflare CLI 工具
- **GitHub Actions** - CI/CD 自动化
- **ESLint** - 代码质量检查

## 📦 项目结构

```
photo-cloud/
├── README.md                   # 项目说明
├── docs/                       # 📚 文档中心
│   ├── README.md              # 文档索引
│   ├── START_HERE.md          # 快速开始
│   ├── DEPLOYMENT.md          # 部署指南
│   ├── SECURITY.md            # 安全指南
│   └── ... (46+ 文档文件)
│
├── frontend/                   # 🎨 Vue 前端项目
│   ├── src/
│   │   ├── api/               # API 接口层
│   │   │   ├── supabase.js    # Supabase 客户端
│   │   │   ├── auth.js        # 认证 API
│   │   │   ├── files.js       # 文件 API
│   │   │   ├── shares.js      # 分享 API
│   │   │   ├── admin.js       # 管理员 API
│   │   │   └── security.js    # 安全 API
│   │   ├── components/        # 🧩 公共组件
│   │   │   ├── FileList.vue
│   │   │   ├── ShareDialog.vue
│   │   │   ├── MarkdownEditor.vue
│   │   │   └── Footer.vue
│   │   ├── pages/             # 📄 页面组件
│   │   │   ├── Login.vue
│   │   │   ├── Dashboard.vue
│   │   │   ├── Upload.vue
│   │   │   ├── Preview.vue
│   │   │   ├── Admin.vue
│   │   │   ├── Settings.vue
│   │   │   └── Share.vue
│   │   ├── layouts/           # 🎭 布局组件
│   │   ├── router/            # 🧭 路由配置
│   │   ├── stores/            # 💾 Pinia 状态管理
│   │   ├── utils/             # 🔧 工具函数
│   │   ├── composables/       # 🎣 组合式函数
│   │   ├── App.vue
│   │   ├── main.js
│   │   └── style.css
│   ├── public/                # 静态资源
│   ├── worker.js              # Cloudflare Worker 脚本
│   ├── wrangler.jsonc         # Wrangler 配置
│   ├── vite.config.js         # Vite 配置
│   ├── package.json
│   └── .env.example           # 环境变量示例
│
├── backend/                    # 🗄️ Supabase 配置
│   ├── sql/                   # 数据库脚本
│   │   ├── 01_tables.sql      # 表结构
│   │   ├── 02_rls.sql         # RLS 策略
│   │   ├── 04_user_management.sql
│   │   ├── 14_security_enhancements.sql
│   │   ├── 15_registration_protection.sql
│   │   ├── 99_check_email_exists.sql
│   │   └── ... (20+ SQL 文件)
│   ├── storage-rules/         # Storage 安全规则
│   └── README.md
│
└── .github/                    # 🤖 GitHub 配置
    └── workflows/
        └── security-check.yml  # 安全检查工作流
```

## 🚀 快速开始

> 💡 **新手？** 建议先阅读 [完整安装教程](./docs/START_HERE.md) 获取详细步骤说明

### 前提条件

- Node.js 16+ 
- npm 或 yarn
- Supabase 账户
- （可选）Cloudflare 账户（用于部署）

### 1. 克隆项目

```bash
git clone https://github.com/xuboboo/photo-cloud.git
cd photo-cloud
```

### 2. 后端设置（Supabase）

1. 访问 [supabase.com](https://supabase.com) 创建新项目
2. 在 SQL Editor 中依次执行 `backend/sql/` 目录下的脚本
   ```
   01_tables.sql → 02_rls.sql → 04_user_management.sql → ...
   ```
3. 在 Storage 中创建名为 `private-files` 的 bucket（私有）
4. 获取项目 URL 和 anon key（Settings → API）

📚 详细步骤：[Supabase 设置指南](./docs/SUPABASE_SETUP_GUIDE.md)

### 3. 前端设置

```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 复制环境变量文件
cp .env.example .env

# 编辑 .env 文件，填入 Supabase 配置
nano .env
```

**.env 配置：**
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

```bash
# 启动开发服务器
npm run dev
```

### 4. 访问应用

- **本地开发**：http://localhost:3000
- **在线演示**：https://www.tournews.top

### 5. 部署到生产环境

#### Cloudflare Workers (推荐)

```bash
# 构建项目
npm run build

# 部署到 Cloudflare
npx wrangler deploy
```

📚 完整部署指南：[部署文档](./docs/DEPLOYMENT.md)

## 📝 使用说明

### 👤 用户功能

#### 注册 & 登录
1. 访问登录页面
2. 选择"注册"或"登录"标签
3. 输入邮箱和密码（密码至少 6 位）
4. （可选）邮箱验证

#### 文件上传
1. 进入控制面板
2. 点击"上传文件"按钮
3. 选择或拖拽文件到上传区域
4. 支持的文件类型：
   - 📷 图片：jpg, png, gif, webp, svg
   - 📝 Markdown：.md, .markdown
   - 📄 文档：txt, pdf (查看模式)
5. 文件大小限制：默认 50MB（可配置）

#### 文件管理
- 📁 创建文件夹分类管理
- 🖼️ 图片预览和下载
- 📝 Markdown 在线编辑和预览
- 🔗 生成分享链接（密码保护、有效期）
- 🗑️ 删除不需要的文件
- 📊 查看存储使用情况

#### 个人设置
- 修改个人信息
- 更改密码
- 查看存储配额
- 查看活动历史

### 👑 管理员功能

- 用户管理（启用/禁用账户）
- 角色分配（普通用户/管理员）
- 存储配额管理
- 邮箱黑名单管理
- 系统活动日志
- 邮箱验证管理
- 密码重置

📚 详细说明：[管理员功能指南](./docs/ADMIN_FEATURES.md)

## 🔒 安全特性

### 认证与授权
- ✅ JWT Token 认证
- ✅ 会话管理和自动刷新
- ✅ 邮箱验证机制
- ✅ 密码强度验证（最少 6 位）
- ✅ 防重复注册检查
- ✅ 管理员角色权限控制

### 数据安全
- ✅ **行级安全策略（RLS）** - PostgreSQL 数据库级别的访问控制
- ✅ **数据隔离** - 用户只能访问自己的数据
- ✅ **私有存储** - 所有文件需要签名 URL 访问
- ✅ **路径安全** - 文件路径包含用户 ID，防止遍历攻击
- ✅ **SQL 注入防护** - 使用参数化查询

### 应用安全
- ✅ 文件类型白名单验证
- ✅ 文件大小限制
- ✅ CSRF 保护
- ✅ XSS 防护
- ✅ 速率限制（防暴力破解）
- ✅ 邮箱黑名单系统
- ✅ IP 封禁机制

### 传输安全
- ✅ HTTPS 加密传输
- ✅ Cloudflare CDN 保护
- ✅ DDoS 防护

📚 详细文档：[安全指南](./docs/SECURITY.md)

## 🛠️ 开发命令

```bash
# 前端开发
cd frontend
npm run dev          # 启动开发服务器
npm run build        # 构建生产版本
npm run preview      # 预览生产构建

# Cloudflare 部署
npx wrangler login   # 登录 Cloudflare
npx wrangler deploy  # 部署到生产环境
npx wrangler tail    # 查看实时日志

# 代码检查
npm run lint         # ESLint 检查
npm run format       # 代码格式化
```

## 📚 核心 API

### 认证 API (`/api/auth.js`)
```javascript
login(email, password)      // 用户登录
register(email, password)   // 用户注册  
logout()                    // 用户登出
getUser()                   // 获取当前用户
```

### 文件 API (`/api/files.js`)
```javascript
uploadFile(file, type, folderId)  // 上传文件
getFiles(folderId)                // 获取文件列表
getFileById(id)                   // 获取单个文件
getSignedUrl(path)                // 获取签名 URL
updateFile(id, updates)           // 更新文件信息
deleteFile(id, path)              // 删除文件
```

### 分享 API (`/api/shares.js`)
```javascript
createFileShare(fileId, options)  // 创建分享链接
getShareByToken(token)            // 通过 token 获取分享
getUserShares()                   // 获取用户的分享列表
deleteShare(shareId)              // 删除分享
```

### 管理员 API (`/api/admin.js`)
```javascript
getAllUsers()                     // 获取所有用户
updateUserStatus(userId, status)  // 更新用户状态
updateUserRole(userId, role)      // 更新用户角色
updateUserQuota(userId, quota)    // 更新存储配额
getActivityLogs()                 // 获取活动日志
```

📚 完整 API 文档：查看各 API 文件的注释说明

## 🎨 界面定制

### 颜色主题

编辑 `frontend/src/style.css` 自定义主题：

```css
:root {
  /* 主色调 */
  --primary-color: #667eea;
  --primary-dark: #764ba2;
  
  /* 功能色 */
  --success-color: #48bb78;
  --error-color: #e53e3e;
  --warning-color: #f6ad55;
  
  /* 中性色 */
  --bg-color: #f7fafc;
  --text-color: #2d3748;
  --border-color: #e2e8f0;
}
```

### 组件样式

所有组件使用 Scoped CSS，样式隔离：
```vue
<style scoped>
/* 组件特定样式 */
</style>
```

## 🐛 故障排查

### 常见问题

**1. Supabase 连接失败**
- 检查 `.env` 文件配置
- 确认 Supabase 项目状态
- 验证 API key 是否正确

**2. 文件上传失败**
- 检查存储配额是否充足
- 验证文件大小和类型
- 查看 Storage 安全策略

**3. 权限问题**
- 确认 RLS 策略已正确配置
- 检查用户角色和权限
- 查看数据库日志

📚 更多问题：[故障排查指南](./docs/TROUBLESHOOTING.md)

## 📊 性能优化

- ✅ 路由懒加载
- ✅ 图片懒加载
- ✅ 组件按需加载
- ✅ 请求缓存策略
- ✅ Vite 构建优化
- ✅ Cloudflare CDN 加速
- ✅ Gzip/Brotli 压缩

📚 详细说明：[性能优化指南](./docs/PERFORMANCE_OPTIMIZATION.md)

## 🧪 测试

```bash
# 单元测试
npm run test

# E2E 测试
npm run test:e2e

# 测试覆盖率
npm run test:coverage
```

📚 测试文档：[测试指南](./docs/TESTING_GUIDE.md)

## 📖 文档

- [快速开始](./docs/START_HERE.md)
- [完整安装教程](./docs/COMPLETE_SETUP_TUTORIAL.md)
- [部署指南](./docs/DEPLOYMENT.md)
- [安全指南](./docs/SECURITY.md)
- [管理员功能](./docs/ADMIN_FEATURES.md)
- [移动端适配](./docs/MOBILE_ADAPTATION.md)
- [故障排查](./docs/TROUBLESHOOTING.md)
- [更多文档...](./docs)

## 🤝 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范
- 遵循 ESLint 规则
- 使用有意义的变量名
- 添加必要的注释
- 保持代码简洁

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 💝 致谢

- [Vue.js](https://vuejs.org/) - 渐进式 JavaScript 框架
- [Supabase](https://supabase.com/) - 开源 Firebase 替代方案
- [Cloudflare](https://www.cloudflare.com/) - 全球 CDN 和边缘计算
- [Vite](https://vitejs.dev/) - 下一代前端构建工具

## 📧 联系方式

- **项目主页**：https://github.com/xuboboo/photo-cloud
- **在线演示**：https://www.tournews.top
- **问题反馈**：[GitHub Issues](https://github.com/xuboboo/photo-cloud/issues)

## ⭐ Star History

如果这个项目对你有帮助，请给它一个 Star ⭐️

---

<div align="center">

**[⬆ 回到顶部](#photo-cloud---专业云相册管理系统)**

Made with ❤️ by [xuboboo](https://github.com/xuboboo)

</div>
