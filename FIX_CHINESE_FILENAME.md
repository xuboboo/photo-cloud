# 🔧 中文文件名支持修复

## 问题说明

Supabase Storage 不支持文件路径中包含中文字符，会返回 `Invalid key` 错误。

## 解决方案

### 1. 文件名处理策略

**存储时**：
- 将中文和特殊字符转换为安全的 ASCII 字符
- 如果转换后为空，使用时间戳作为文件名

**显示时**：
- 在数据库中保存原始文件名（包含中文）
- 界面上显示原始文件名

### 2. 实现细节

#### 文件名转换规则
```javascript
const safeName = documentName.value
  .replace(/[^\w\s-]/g, '') // 移除特殊字符
  .replace(/\s+/g, '-')     // 空格转为连字符
  .toLowerCase()

// 如果处理后为空（全是中文），使用时间戳
const finalName = safeName || `document-${Date.now()}`
```

#### 示例转换

| 原始文件名 | 转换后文件名 | 说明 |
|-----------|-------------|------|
| 新建Markdown | document-1763830231502 | 全中文，使用时间戳 |
| My Document | my-document | 英文，转小写加连字符 |
| 测试-Test | test | 保留英文部分 |
| README | readme | 直接转小写 |

---

## 🚀 修复步骤

### 步骤 1：更新数据库（添加原始文件名字段）

在 Supabase SQL Editor 中执行：

```sql
-- 添加 original_name 字段
ALTER TABLE files 
ADD COLUMN IF NOT EXISTS original_name text;

-- 更新现有文件
UPDATE files 
SET original_name = name 
WHERE original_name IS NULL;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_files_original_name ON files(original_name);
```

或者直接执行 `backend/sql/08_add_original_name.sql`

### 步骤 2：刷新浏览器

1. 硬刷新（Ctrl+Shift+R）
2. 重新登录（如果需要）

### 步骤 3：测试

1. 点击"📝 新建文档"
2. 输入中文文件名，如"我的文档"
3. 编辑内容
4. 保存
5. 在文件列表中应该显示"我的文档.md"

---

## ✅ 已修复的文件

1. ✅ `frontend/src/pages/CreateDocument.vue`
   - 添加文件名安全转换
   - 传递原始文件名

2. ✅ `frontend/src/api/files.js`
   - 支持 `originalName` 参数
   - 保存到数据库

3. ✅ `frontend/src/components/FileList.vue`
   - 显示原始文件名（中文）

4. ✅ `backend/sql/08_add_original_name.sql`
   - 数据库字段添加

---

## 📝 使用示例

### 创建中文文档

```javascript
// 用户输入：新建Markdown
// 实际存储：document-1763830231502.md
// 数据库记录：
{
  name: 'document-1763830231502.md',
  original_name: '新建Markdown.md',
  path: 'markdown/user-id/1763830231502-document-1763830231502.md'
}
// 界面显示：新建Markdown.md
```

### 创建英文文档

```javascript
// 用户输入：My Project README
// 实际存储：my-project-readme.md
// 数据库记录：
{
  name: 'my-project-readme.md',
  original_name: 'My Project README.md',
  path: 'markdown/user-id/1763830231502-my-project-readme.md'
}
// 界面显示：My Project README.md
```

---

## 🎯 优势

1. **兼容性**：Storage 路径只包含 ASCII 字符
2. **用户友好**：界面显示原始中文名称
3. **可搜索**：保留原始名称便于搜索
4. **向后兼容**：现有文件自动使用 `name` 作为 `original_name`

---

## 🔍 验证方法

### 检查数据库

```sql
SELECT 
  name,
  original_name,
  path,
  created_at
FROM files
ORDER BY created_at DESC
LIMIT 10;
```

应该看到：
- `name`: 安全的 ASCII 文件名
- `original_name`: 原始文件名（可能包含中文）
- `path`: Storage 路径（只包含 ASCII）

### 检查界面

1. 文件列表应该显示中文文件名
2. 下载文件时使用原始文件名
3. 预览时显示原始文件名

---

## 🎉 完成！

现在系统完全支持中文文件名：

✅ 创建中文文档  
✅ 显示中文文件名  
✅ Storage 兼容性  
✅ 向后兼容  

**可以放心使用中文文件名了！** 🚀
