# 部署指南

本文档介绍如何将文件管理系统部署到生产环境。

## 📋 部署前准备

### 1. Supabase 生产环境配置

1. 确保已完成所有 SQL 脚本的执行
2. 配置 Storage bucket 和策略
3. 设置邮箱认证（可选）
4. 配置自定义域名（可选）
5. 启用数据库备份

### 2. 环境变量配置

创建生产环境的 `.env` 文件：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-production-anon-key
```

## 🚀 部署选项

### 选项 1: Vercel（推荐）

Vercel 是部署 Vue 应用的最佳选择之一。

#### 步骤：

1. 安装 Vercel CLI
```bash
npm install -g vercel
```

2. 在项目根目录运行
```bash
cd frontend
vercel
```

3. 按照提示配置项目

4. 设置环境变量
   - 在 Vercel Dashboard 中添加环境变量
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

5. 部署
```bash
vercel --prod
```

#### vercel.json 配置（可选）

在 `frontend/` 目录创建 `vercel.json`：

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### 选项 2: Netlify

1. 安装 Netlify CLI
```bash
npm install -g netlify-cli
```

2. 构建项目
```bash
cd frontend
npm run build
```

3. 部署
```bash
netlify deploy --prod --dir=dist
```

4. 在 Netlify Dashboard 中配置环境变量

#### netlify.toml 配置

在 `frontend/` 目录创建 `netlify.toml`：

```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 选项 3: 自托管（Nginx）

#### 1. 构建项目

```bash
cd frontend
npm install
npm run build
```

#### 2. Nginx 配置

```nginx
server {
    listen 80;
    server_name your-domain.com;

    root /var/www/file-manager/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 启用 gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 缓存静态资源
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 3. 部署步骤

```bash
# 上传构建文件到服务器
scp -r dist/* user@server:/var/www/file-manager/dist/

# 重启 Nginx
sudo systemctl restart nginx
```

### 选项 4: Docker

#### Dockerfile

在 `frontend/` 目录创建 `Dockerfile`：

```dockerfile
# 构建阶段
FROM node:18-alpine as build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# 生产阶段
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### nginx.conf

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

#### 构建和运行

```bash
# 构建镜像
docker build -t file-manager:latest .

# 运行容器
docker run -d -p 80:80 --name file-manager file-manager:latest
```

## 🔒 生产环境安全建议

### 1. Supabase 安全配置

- ✅ 启用 RLS（行级安全策略）
- ✅ 配置 CORS 白名单
- ✅ 启用邮箱验证
- ✅ 设置密码强度要求
- ✅ 配置 Rate Limiting
- ✅ 定期备份数据库

### 2. 前端安全

- ✅ 使用 HTTPS
- ✅ 配置 CSP（内容安全策略）
- ✅ 启用 HSTS
- ✅ 不要在前端代码中暴露敏感信息
- ✅ 使用环境变量管理配置

### 3. Storage 安全

- ✅ 确保 bucket 设置为私有
- ✅ 配置正确的 Storage 策略
- ✅ 设置文件大小限制
- ✅ 验证文件类型
- ✅ 使用签名 URL 访问文件

## 📊 性能优化

### 1. 前端优化

- ✅ 启用代码分割
- ✅ 压缩静态资源
- ✅ 使用 CDN
- ✅ 启用浏览器缓存
- ✅ 图片懒加载
- ✅ 使用 Web Workers（如需要）

### 2. Supabase 优化

- ✅ 创建数据库索引
- ✅ 使用连接池
- ✅ 配置 CDN for Storage
- ✅ 启用 Realtime 订阅（如需要）

## 🔍 监控和日志

### 1. 前端监控

推荐使用：
- Sentry - 错误追踪
- Google Analytics - 用户分析
- Vercel Analytics - 性能监控

### 2. 后端监控

Supabase Dashboard 提供：
- 数据库性能监控
- API 请求统计
- Storage 使用情况
- 认证统计

## 🔄 CI/CD 配置

### GitHub Actions 示例

在 `.github/workflows/deploy.yml`：

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          cd frontend
          npm ci

      - name: Build
        run: |
          cd frontend
          npm run build
        env:
          VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
```

## 📝 部署检查清单

部署前确认：

- [ ] 所有 SQL 脚本已执行
- [ ] Storage bucket 已创建并配置
- [ ] 环境变量已正确设置
- [ ] RLS 策略已启用
- [ ] 邮箱认证已配置（如需要）
- [ ] 前端代码已构建
- [ ] HTTPS 已配置
- [ ] 域名已解析
- [ ] 备份策略已设置
- [ ] 监控已配置

## 🆘 故障排查

### 常见问题

1. **无法连接到 Supabase**
   - 检查环境变量是否正确
   - 确认 Supabase 项目状态
   - 检查网络连接

2. **文件上传失败**
   - 检查 Storage bucket 是否存在
   - 确认 Storage 策略配置正确
   - 检查文件大小限制

3. **登录失败**
   - 确认邮箱验证设置
   - 检查 RLS 策略
   - 查看 Supabase 日志

4. **路由 404 错误**
   - 确认服务器配置了 SPA 重定向
   - 检查 Nginx/Vercel 配置

## 📞 支持

如遇到部署问题，请：
1. 查看 Supabase 文档
2. 检查浏览器控制台错误
3. 查看服务器日志
4. 提交 Issue
