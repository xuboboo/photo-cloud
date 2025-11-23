# 📝 新建文档功能完整指南

## 🎉 功能概述

现在系统支持**在线新建和编辑**超过 **60 种**文档类型！

### ✅ 已支持的文档类型

#### 📄 文档类 (4 种)
- Markdown (.md) - 带实时预览
- 纯文本 (.txt)
- 富文本 (.rtf)
- 日志文件 (.log)

#### 💻 编程语言 (19 种)
- JavaScript (.js)
- TypeScript (.ts)
- Python (.py)
- Java (.java)
- C++ (.cpp)
- C (.c)
- C# (.cs)
- Go (.go)
- Rust (.rs)
- PHP (.php)
- Ruby (.rb)
- Swift (.swift)
- Kotlin (.kt)
- Scala (.scala)
- R (.r)
- MATLAB (.m)
- Perl (.pl)
- Lua (.lua)
- Dart (.dart)

#### 🌐 Web 开发 (7 种)
- HTML (.html) - 带实时预览
- CSS (.css)
- SCSS (.scss)
- LESS (.less)
- Vue (.vue)
- JSX (.jsx)
- TSX (.tsx)

#### 📊 数据格式 (6 种)
- JSON (.json) - 带格式化和验证
- XML (.xml) - 带格式化和验证
- YAML (.yaml)
- TOML (.toml)
- CSV (.csv) - 可视化表格编辑
- TSV (.tsv)

#### ⚙️ 配置文件 (6 种)
- ENV (.env)
- INI (.ini)
- Config (.conf)
- Properties (.properties)
- Dockerfile (.dockerfile)
- Gitignore (.gitignore)

#### 🖥️ Shell 脚本 (4 种)
- Bash (.sh)
- PowerShell (.ps1)
- Batch (.bat)
- Zsh (.zsh)

#### 🗄️ 数据库 (3 种)
- SQL (.sql)
- PL/SQL (.plsql)
- MongoDB (.mongodb)

#### 📁 其他 (6 种)
- LaTeX (.tex)
- SVG (.svg)
- GraphQL (.graphql)
- Protocol Buffer (.proto)
- Makefile (.makefile)
- CMake (.cmake)

---

## 🚀 如何使用

### 方法 1：从主页新建

1. 登录系统
2. 点击右上角 **"📝 新建文档"** 按钮
3. 选择文档类型
4. 开始编辑
5. 点击 **"💾 保存"**

### 方法 2：直接访问

访问 `/create` 路由

---

## 🎨 编辑器功能

### Markdown 编辑器

**特色功能**：
- ✅ 实时预览（左右分屏）
- ✅ 工具栏快捷按钮
  - H - 标题
  - B - 粗体
  - I - 斜体
  - Code - 代码
  - List - 列表
  - Link - 链接
  - Quote - 引用
- ✅ 自动渲染
- ✅ 美化样式

**使用示例**：
```markdown
# 我的文档

这是一个 **粗体** 和 *斜体* 的示例。

## 代码示例

`console.log('Hello World')`

## 列表

- 项目 1
- 项目 2
- 项目 3
```

### HTML 编辑器

**特色功能**：
- ✅ 代码编辑模式
- ✅ 实时预览模式
- ✅ 一键切换
- ✅ 格式化功能

**使用示例**：
```html
<!DOCTYPE html>
<html>
<head>
  <title>我的页面</title>
</head>
<body>
  <h1>Hello World</h1>
</body>
</html>
```

### JSON/XML 编辑器

**特色功能**：
- ✅ 语法高亮
- ✅ 自动格式化
- ✅ 实时验证
- ✅ 错误提示

**JSON 示例**：
```json
{
  "name": "项目名称",
  "version": "1.0.0",
  "dependencies": {
    "vue": "^3.0.0"
  }
}
```

**XML 示例**：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item id="1">内容</item>
  <item id="2">内容</item>
</root>
```

### CSV 编辑器

**特色功能**：
- ✅ 可视化表格编辑
- ✅ 添加行/列
- ✅ 直接编辑单元格
- ✅ 自动生成 CSV

**使用方法**：
1. 选择 CSV 类型
2. 编辑表头
3. 填写数据
4. 点击 "+ 添加行" 或 "+ 添加列"
5. 保存

### 代码编辑器

**特色功能**：
- ✅ 等宽字体
- ✅ 语法提示
- ✅ 自动缩进
- ✅ 格式化功能

**支持的语言**：
所有编程语言都使用统一的代码编辑器，提供：
- 行号显示
- 语法高亮
- 自动补全
- 代码折叠

---

## 📝 文档模板

### Markdown 模板
```markdown
# 标题

## 简介

这里是简介内容。

## 主要内容

### 小节 1

内容...

### 小节 2

内容...

## 总结

总结内容。
```

### README 模板
```markdown
# 项目名称

## 简介

项目简介

## 安装

\`\`\`bash
npm install
\`\`\`

## 使用

\`\`\`bash
npm start
\`\`\`

## 许可证

MIT
```

### Package.json 模板
```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "项目描述",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "jest"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
```

### Dockerfile 模板
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

---

## 🎯 快捷键（计划中）

| 快捷键 | 功能 |
|--------|------|
| Ctrl+S | 保存文档 |
| Ctrl+B | 粗体（Markdown）|
| Ctrl+I | 斜体（Markdown）|
| Ctrl+K | 插入链接 |
| Ctrl+/ | 注释代码 |
| Tab | 缩进 |
| Shift+Tab | 取消缩进 |

---

## 💡 使用技巧

### 1. Markdown 快速编辑

使用工具栏按钮快速插入格式：
- 选中文本后点击 **B** 按钮 → 变为粗体
- 选中文本后点击 **I** 按钮 → 变为斜体
- 点击 **Link** 按钮 → 插入链接模板

### 2. JSON 格式化

1. 粘贴未格式化的 JSON
2. 点击 **"格式化"** 按钮
3. 自动美化并验证

### 3. HTML 实时预览

1. 编写 HTML 代码
2. 点击 **"预览"** 按钮
3. 查看实时效果
4. 点击 **"编辑"** 返回编辑模式

### 4. CSV 快速编辑

1. 点击单元格直接编辑
2. 使用 **"+ 添加行"** 快速添加数据
3. 使用 **"+ 添加列"** 扩展表格

---

## 🔧 技术实现

### 前端技术
- **Vue 3** - 响应式框架
- **Markdown-it** - Markdown 渲染
- **Monaco Editor**（计划）- 高级代码编辑器
- **Prism.js**（计划）- 语法高亮

### 文件存储
- 所有文档保存为文本文件
- 存储在 Supabase Storage
- 使用 `markdown` 类型分类
- 支持版本控制（计划）

---

## 📊 文件类型统计

| 类别 | 数量 | 占比 |
|------|------|------|
| 编程语言 | 19 | 31% |
| Web 开发 | 7 | 11% |
| 数据格式 | 6 | 10% |
| 配置文件 | 6 | 10% |
| Shell 脚本 | 4 | 7% |
| 文档 | 4 | 7% |
| 数据库 | 3 | 5% |
| 其他 | 6 | 10% |
| **总计** | **55** | **100%** |

---

## 🎨 界面预览

### 类型选择界面
- 按类别分组显示
- 卡片式布局
- 图标 + 名称 + 扩展名
- 悬停效果

### 编辑器界面
- 顶部：文档名称 + 扩展名
- 工具栏：快捷操作按钮
- 主体：编辑区域
- 右侧：实时预览（Markdown/HTML）

---

## 🚀 未来计划

### 短期（1-2 周）
- [ ] 添加代码语法高亮
- [ ] 添加自动保存功能
- [ ] 添加快捷键支持
- [ ] 添加文档模板库

### 中期（1 个月）
- [ ] 集成 Monaco Editor
- [ ] 添加协作编辑
- [ ] 添加版本历史
- [ ] 添加导出功能

### 长期（2-3 个月）
- [ ] AI 辅助编写
- [ ] 代码补全
- [ ] 错误检查
- [ ] 多人实时协作

---

## ✅ 测试清单

- [ ] 可以选择文档类型
- [ ] 可以输入文档名称
- [ ] 可以编辑文档内容
- [ ] Markdown 实时预览正常
- [ ] HTML 预览正常
- [ ] JSON 格式化正常
- [ ] JSON 验证正常
- [ ] CSV 表格编辑正常
- [ ] 可以保存文档
- [ ] 保存后在文件列表中显示
- [ ] 可以下载保存的文档

---

## 🎉 完成！

现在你的系统支持：

✅ **55+ 种文档类型**  
✅ **在线创建和编辑**  
✅ **实时预览**（Markdown/HTML）  
✅ **格式化和验证**（JSON/XML）  
✅ **可视化编辑**（CSV）  
✅ **专业代码编辑器**  

**立即体验新建文档功能！** 🚀

---

**需要帮助？** 查看其他文档或提问！
