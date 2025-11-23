<template>
  <MobileLayout title="新建文档" :show-back="true">
    <!-- 移动端和桌面端共用内容 -->
    <div class="create-content-wrapper">
      <!-- 文档类型选择 -->
      <div class="type-selection" v-if="!selectedType">
        <h2>选择文档类型</h2>
        
        <div class="type-categories">
          <div v-for="category in documentCategories" :key="category.name" class="category-section">
            <h3>{{ category.icon }} {{ category.name }}</h3>
            <div class="type-grid">
              <div 
                v-for="type in category.types" 
                :key="type.id"
                @click="selectType(type)"
                class="type-card"
              >
                <div class="type-icon">{{ type.icon }}</div>
                <div class="type-info">
                  <div class="type-name">{{ type.name }}</div>
                  <div class="type-ext">{{ type.extension }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 文档编辑器 -->
      <div class="document-editor" v-else>
        <div class="editor-header">
          <div class="editor-info">
            <span class="doc-icon">{{ selectedType.icon }}</span>
            <input 
              v-model="documentName" 
              type="text" 
              placeholder="输入文档名称"
              class="doc-name-input"
            />
            <span class="doc-ext">.{{ selectedType.extension }}</span>
          </div>
          <div class="editor-actions">
            <button @click="selectedType = null" class="btn-change">更换类型</button>
            <button @click="saveDocument" :disabled="saving" class="btn-save">
              {{ saving ? '保存中...' : '💾 保存' }}
            </button>
          </div>
        </div>

        <div class="editor-body">
          <!-- Markdown 编辑器 -->
          <div v-if="selectedType.category === 'markdown'" class="markdown-editor">
            <div class="editor-toolbar">
              <div class="toolbar-section">
                <button @click="insertMarkdown('# ')" class="toolbar-btn" title="标题">
                  <span class="btn-icon">H₁</span>
                </button>
                <button @click="insertMarkdown('## ')" class="toolbar-btn" title="二级标题">
                  <span class="btn-icon">H₂</span>
                </button>
                <span class="toolbar-divider"></span>
                <button @click="insertMarkdown('**', '**')" class="toolbar-btn" title="粗体">
                  <span class="btn-icon">𝐁</span>
                </button>
                <button @click="insertMarkdown('*', '*')" class="toolbar-btn" title="斜体">
                  <span class="btn-icon">𝐼</span>
                </button>
                <button @click="insertMarkdown('~~', '~~')" class="toolbar-btn" title="删除线">
                  <span class="btn-icon">S</span>
                </button>
                <span class="toolbar-divider"></span>
                <button @click="insertMarkdown('`', '`')" class="toolbar-btn" title="行内代码">
                  <span class="btn-icon">&lt;/&gt;</span>
                </button>
                <button @click="insertMarkdown('```\n', '\n```')" class="toolbar-btn" title="代码块">
                  <span class="btn-icon">{ }</span>
                </button>
                <span class="toolbar-divider"></span>
                <button @click="insertMarkdown('- ')" class="toolbar-btn" title="无序列表">
                  <span class="btn-icon">☰</span>
                </button>
                <button @click="insertMarkdown('1. ')" class="toolbar-btn" title="有序列表">
                  <span class="btn-icon">1.</span>
                </button>
                <button @click="insertMarkdown('- [ ] ')" class="toolbar-btn" title="任务列表">
                  <span class="btn-icon">☑</span>
                </button>
                <span class="toolbar-divider"></span>
                <button @click="insertMarkdown('[', '](url)')" class="toolbar-btn" title="链接">
                  <span class="btn-icon">🔗</span>
                </button>
                <button @click="insertMarkdown('> ')" class="toolbar-btn" title="引用">
                  <span class="btn-icon">❝</span>
                </button>
                <button @click="insertMarkdown('---\n')" class="toolbar-btn" title="分割线">
                  <span class="btn-icon">―</span>
                </button>
              </div>
              <div class="toolbar-right">
                <button 
                  @click="toggleViewMode" 
                  class="btn-view-mode"
                  :class="'mode-' + viewMode"
                  :title="getModeTitle"
                >
                  {{ getModeLabel }}
                </button>
              </div>
            </div>
            <div class="editor-split" :class="'mode-' + viewMode">
              <textarea 
                ref="markdownTextarea"
                v-model="documentContent" 
                placeholder="开始编写 Markdown..."
                class="markdown-input"
                v-show="viewMode === 'edit' || viewMode === 'split'"
              ></textarea>
              <div 
                class="markdown-preview" 
                v-html="markdownPreview"
                v-show="viewMode === 'preview' || viewMode === 'split'"
              ></div>
            </div>
          </div>

          <!-- 纯文本编辑器 -->
          <div v-else-if="selectedType.category === 'text'" class="text-editor">
            <textarea 
              v-model="documentContent" 
              :placeholder="'开始编写 ' + selectedType.name + '...'"
              class="text-input"
            ></textarea>
          </div>

          <!-- 代码编辑器 -->
          <div v-else-if="selectedType.category === 'code'" class="code-editor">
            <div class="editor-toolbar">
              <span class="language-label">{{ selectedType.name }}</span>
              <button @click="formatCode" class="btn-format">格式化</button>
            </div>
            <textarea 
              v-model="documentContent" 
              :placeholder="'编写 ' + selectedType.name + ' 代码...'"
              class="code-input"
              spellcheck="false"
            ></textarea>
          </div>

          <!-- JSON/XML 编辑器 -->
          <div v-else-if="['json', 'xml'].includes(selectedType.category)" class="structured-editor">
            <div class="editor-toolbar">
              <button @click="formatStructured" class="btn-format">格式化</button>
              <button @click="validateStructured" class="btn-validate">验证</button>
            </div>
            <textarea 
              v-model="documentContent" 
              :placeholder="getStructuredPlaceholder()"
              class="structured-input"
              spellcheck="false"
            ></textarea>
            <div v-if="validationMessage" :class="['validation-message', validationError ? 'error' : 'success']">
              {{ validationMessage }}
            </div>
          </div>

          <!-- CSV 编辑器 -->
          <div v-else-if="selectedType.category === 'data'" class="csv-editor">
            <div class="editor-toolbar">
              <button @click="addRow" class="btn-add">+ 添加行</button>
              <button @click="addColumn" class="btn-add">+ 添加列</button>
            </div>
            <div class="csv-table">
              <table>
                <thead>
                  <tr>
                    <th v-for="(col, index) in csvHeaders" :key="index">
                      <input v-model="csvHeaders[index]" placeholder="列名" />
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, rowIndex) in csvData" :key="rowIndex">
                    <td v-for="(cell, colIndex) in row" :key="colIndex">
                      <input v-model="csvData[rowIndex][colIndex]" />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- HTML 编辑器 -->
          <div v-else-if="selectedType.category === 'html'" class="html-editor">
            <div class="editor-toolbar">
              <button @click="formatCode" class="btn-format">格式化</button>
              <button @click="togglePreview" class="btn-preview">
                {{ showHtmlPreview ? '编辑' : '预览' }}
              </button>
            </div>
            <textarea 
              v-if="!showHtmlPreview"
              v-model="documentContent" 
              placeholder="编写 HTML..."
              class="html-input"
              spellcheck="false"
            ></textarea>
            <iframe 
              v-else
              :srcdoc="documentContent"
              class="html-preview"
              sandbox="allow-scripts"
            ></iframe>
          </div>

          <!-- 其他类型的基础编辑器 -->
          <div v-else class="basic-editor">
            <textarea 
              v-model="documentContent" 
              :placeholder="'编写 ' + selectedType.name + '...'"
              class="basic-input"
            ></textarea>
          </div>
        </div>
      </div>
    </div>
  </MobileLayout>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import MobileLayout from '../layouts/MobileLayout.vue'
import { uploadFile } from '../api/files'
import { renderMarkdown } from '../utils/markdown'
import { logActivity } from '../api/admin'

const router = useRouter()

const selectedType = ref(null)
const documentName = ref('')
const documentContent = ref('')
const saving = ref(false)
const showHtmlPreview = ref(false)
const validationMessage = ref('')
const validationError = ref(false)

// 视图模式：edit(编辑), preview(预览), split(分屏)
const viewMode = ref('split')

// 切换视图模式
const toggleViewMode = () => {
  const modes = ['edit', 'preview', 'split']
  const currentIndex = modes.indexOf(viewMode.value)
  viewMode.value = modes[(currentIndex + 1) % modes.length]
}

// 移动端默认编辑模式
if (window.innerWidth <= 768) {
  viewMode.value = 'edit'
}

// CSV 编辑器数据
const csvHeaders = ref(['列1', '列2', '列3'])
const csvData = ref([
  ['', '', ''],
  ['', '', '']
])

const markdownTextarea = ref(null)

// 文档类型分类
const documentCategories = [
  {
    name: '文档',
    icon: '📄',
    types: [
      { id: 'markdown', name: 'Markdown', extension: 'md', icon: '📝', category: 'markdown' },
      { id: 'text', name: '纯文本', extension: 'txt', icon: '📃', category: 'text' },
      { id: 'rtf', name: '富文本', extension: 'rtf', icon: '📋', category: 'text' },
      { id: 'log', name: '日志文件', extension: 'log', icon: '📊', category: 'text' },
    ]
  },
  {
    name: '编程语言',
    icon: '💻',
    types: [
      { id: 'javascript', name: 'JavaScript', extension: 'js', icon: '🟨', category: 'code' },
      { id: 'typescript', name: 'TypeScript', extension: 'ts', icon: '🔷', category: 'code' },
      { id: 'python', name: 'Python', extension: 'py', icon: '🐍', category: 'code' },
      { id: 'java', name: 'Java', extension: 'java', icon: '☕', category: 'code' },
      { id: 'cpp', name: 'C++', extension: 'cpp', icon: '⚙️', category: 'code' },
      { id: 'c', name: 'C', extension: 'c', icon: '🔧', category: 'code' },
      { id: 'csharp', name: 'C#', extension: 'cs', icon: '🎯', category: 'code' },
      { id: 'go', name: 'Go', extension: 'go', icon: '🐹', category: 'code' },
      { id: 'rust', name: 'Rust', extension: 'rs', icon: '🦀', category: 'code' },
      { id: 'php', name: 'PHP', extension: 'php', icon: '🐘', category: 'code' },
      { id: 'ruby', name: 'Ruby', extension: 'rb', icon: '💎', category: 'code' },
      { id: 'swift', name: 'Swift', extension: 'swift', icon: '🦅', category: 'code' },
      { id: 'kotlin', name: 'Kotlin', extension: 'kt', icon: '🎨', category: 'code' },
      { id: 'scala', name: 'Scala', extension: 'scala', icon: '🔺', category: 'code' },
      { id: 'r', name: 'R', extension: 'r', icon: '📈', category: 'code' },
      { id: 'matlab', name: 'MATLAB', extension: 'm', icon: '🔢', category: 'code' },
      { id: 'perl', name: 'Perl', extension: 'pl', icon: '🐪', category: 'code' },
      { id: 'lua', name: 'Lua', extension: 'lua', icon: '🌙', category: 'code' },
      { id: 'dart', name: 'Dart', extension: 'dart', icon: '🎯', category: 'code' },
    ]
  },
  {
    name: 'Web 开发',
    icon: '🌐',
    types: [
      { id: 'html', name: 'HTML', extension: 'html', icon: '🌐', category: 'html' },
      { id: 'css', name: 'CSS', extension: 'css', icon: '🎨', category: 'code' },
      { id: 'scss', name: 'SCSS', extension: 'scss', icon: '💅', category: 'code' },
      { id: 'less', name: 'LESS', extension: 'less', icon: '📐', category: 'code' },
      { id: 'vue', name: 'Vue', extension: 'vue', icon: '💚', category: 'code' },
      { id: 'jsx', name: 'JSX', extension: 'jsx', icon: '⚛️', category: 'code' },
      { id: 'tsx', name: 'TSX', extension: 'tsx', icon: '⚛️', category: 'code' },
    ]
  },
  {
    name: '数据格式',
    icon: '📊',
    types: [
      { id: 'json', name: 'JSON', extension: 'json', icon: '📦', category: 'json' },
      { id: 'xml', name: 'XML', extension: 'xml', icon: '📋', category: 'xml' },
      { id: 'yaml', name: 'YAML', extension: 'yaml', icon: '📝', category: 'text' },
      { id: 'toml', name: 'TOML', extension: 'toml', icon: '⚙️', category: 'text' },
      { id: 'csv', name: 'CSV', extension: 'csv', icon: '📊', category: 'data' },
      { id: 'tsv', name: 'TSV', extension: 'tsv', icon: '📋', category: 'data' },
    ]
  },
  {
    name: '配置文件',
    icon: '⚙️',
    types: [
      { id: 'env', name: 'ENV', extension: 'env', icon: '🔐', category: 'text' },
      { id: 'ini', name: 'INI', extension: 'ini', icon: '⚙️', category: 'text' },
      { id: 'conf', name: 'Config', extension: 'conf', icon: '🔧', category: 'text' },
      { id: 'properties', name: 'Properties', extension: 'properties', icon: '📝', category: 'text' },
      { id: 'dockerfile', name: 'Dockerfile', extension: 'dockerfile', icon: '🐳', category: 'code' },
      { id: 'gitignore', name: 'Gitignore', extension: 'gitignore', icon: '🚫', category: 'text' },
    ]
  },
  {
    name: 'Shell 脚本',
    icon: '🖥️',
    types: [
      { id: 'bash', name: 'Bash', extension: 'sh', icon: '🐚', category: 'code' },
      { id: 'powershell', name: 'PowerShell', extension: 'ps1', icon: '💙', category: 'code' },
      { id: 'batch', name: 'Batch', extension: 'bat', icon: '⚡', category: 'code' },
      { id: 'zsh', name: 'Zsh', extension: 'zsh', icon: '🔷', category: 'code' },
    ]
  },
  {
    name: '数据库',
    icon: '🗄️',
    types: [
      { id: 'sql', name: 'SQL', extension: 'sql', icon: '🗄️', category: 'code' },
      { id: 'plsql', name: 'PL/SQL', extension: 'plsql', icon: '📊', category: 'code' },
      { id: 'mongodb', name: 'MongoDB', extension: 'mongodb', icon: '🍃', category: 'code' },
    ]
  },
  {
    name: '其他',
    icon: '📁',
    types: [
      { id: 'latex', name: 'LaTeX', extension: 'tex', icon: '📐', category: 'text' },
      { id: 'svg', name: 'SVG', extension: 'svg', icon: '🎨', category: 'xml' },
      { id: 'graphql', name: 'GraphQL', extension: 'graphql', icon: '🔷', category: 'code' },
      { id: 'proto', name: 'Protocol Buffer', extension: 'proto', icon: '📦', category: 'code' },
      { id: 'makefile', name: 'Makefile', extension: 'makefile', icon: '🔨', category: 'text' },
      { id: 'cmake', name: 'CMake', extension: 'cmake', icon: '⚙️', category: 'text' },
    ]
  }
]

const markdownPreview = computed(() => {
  if (selectedType.value?.category === 'markdown') {
    return renderMarkdown(documentContent.value)
  }
  return ''
})

// 模式按钮标签
const getModeLabel = computed(() => {
  const labels = {
    edit: '👁️ 预览',
    preview: '📱 分屏',
    split: '✏️ 编辑'
  }
  return labels[viewMode.value] || '切换'
})

// 模式提示
const getModeTitle = computed(() => {
  const titles = {
    edit: '点击切换到预览模式',
    preview: '点击切换到分屏模式',
    split: '点击切换到编辑模式'
  }
  return titles[viewMode.value] || '切换视图模式'
})

function selectType(type) {
  selectedType.value = type
  documentName.value = `新建${type.name}`
  
  // 根据类型设置默认内容
  if (type.category === 'markdown') {
    documentContent.value = `开始编写你的内容...

## 常用语法

**粗体** 和 *斜体* 以及 ~~删除线~~

### 列表
- 无序列表项
- 另一个列表项

### 代码
\`行内代码\` 或代码块：

\`\`\`javascript
console.log('Hello World');
\`\`\`

### 其他
> 引用文字

[链接文字](https://example.com)
`
  } else if (type.category === 'html') {
    documentContent.value = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${documentName.value}</title>
</head>
<body>
  <h1>Hello World</h1>
</body>
</html>`
  } else if (type.category === 'json') {
    documentContent.value = `{\n  "name": "${documentName.value}",\n  "version": "1.0.0"\n}`
  } else if (type.category === 'xml') {
    documentContent.value = `<?xml version="1.0" encoding="UTF-8"?>\n<root>\n  <item>内容</item>\n</root>`
  } else {
    documentContent.value = ''
  }
}

function insertMarkdown(before, after = '') {
  const textarea = markdownTextarea.value
  if (!textarea) return
  
  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = documentContent.value.substring(start, end)
  const newText = before + selectedText + after
  
  documentContent.value = 
    documentContent.value.substring(0, start) +
    newText +
    documentContent.value.substring(end)
  
  // 设置光标位置
  setTimeout(() => {
    textarea.focus()
    textarea.setSelectionRange(start + before.length, start + before.length + selectedText.length)
  }, 0)
}

function formatCode() {
  // 简单的代码格式化
  try {
    if (selectedType.value.category === 'json') {
      const parsed = JSON.parse(documentContent.value)
      documentContent.value = JSON.stringify(parsed, null, 2)
    } else if (selectedType.value.category === 'html') {
      // 简单的 HTML 格式化
      documentContent.value = documentContent.value
        .replace(/></g, '>\n<')
        .split('\n')
        .map(line => line.trim())
        .join('\n')
    }
  } catch (error) {
    alert('格式化失败：' + error.message)
  }
}

function formatStructured() {
  try {
    if (selectedType.value.category === 'json') {
      const parsed = JSON.parse(documentContent.value)
      documentContent.value = JSON.stringify(parsed, null, 2)
      validationMessage.value = '✓ 格式化成功'
      validationError.value = false
    } else if (selectedType.value.category === 'xml') {
      // 简单的 XML 格式化
      documentContent.value = documentContent.value
        .replace(/></g, '>\n<')
        .split('\n')
        .map(line => line.trim())
        .join('\n')
      validationMessage.value = '✓ 格式化成功'
      validationError.value = false
    }
    setTimeout(() => {
      validationMessage.value = ''
    }, 3000)
  } catch (error) {
    validationMessage.value = '✗ 格式化失败：' + error.message
    validationError.value = true
  }
}

function validateStructured() {
  try {
    if (selectedType.value.category === 'json') {
      JSON.parse(documentContent.value)
      validationMessage.value = '✓ JSON 格式正确'
      validationError.value = false
    } else if (selectedType.value.category === 'xml') {
      const parser = new DOMParser()
      const doc = parser.parseFromString(documentContent.value, 'text/xml')
      const error = doc.querySelector('parsererror')
      if (error) {
        throw new Error('XML 格式错误')
      }
      validationMessage.value = '✓ XML 格式正确'
      validationError.value = false
    }
    setTimeout(() => {
      validationMessage.value = ''
    }, 3000)
  } catch (error) {
    validationMessage.value = '✗ 验证失败：' + error.message
    validationError.value = true
  }
}

function getStructuredPlaceholder() {
  if (selectedType.value.category === 'json') {
    return '{\n  "key": "value"\n}'
  } else if (selectedType.value.category === 'xml') {
    return '<?xml version="1.0"?>\n<root>\n  <item>content</item>\n</root>'
  }
  return ''
}

function addRow() {
  csvData.value.push(new Array(csvHeaders.value.length).fill(''))
}

function addColumn() {
  csvHeaders.value.push(`列${csvHeaders.value.length + 1}`)
  csvData.value.forEach(row => row.push(''))
}

function togglePreview() {
  showHtmlPreview.value = !showHtmlPreview.value
}

async function saveDocument() {
  if (!documentName.value.trim()) {
    alert('请输入文档名称')
    return
  }
  
  if (!documentContent.value.trim() && selectedType.value.category !== 'data') {
    alert('文档内容不能为空')
    return
  }
  
  try {
    saving.value = true
    
    // 处理 CSV 数据
    let content = documentContent.value
    if (selectedType.value.category === 'data') {
      content = csvHeaders.value.join(',') + '\n' +
                csvData.value.map(row => row.join(',')).join('\n')
    }
    
    // 创建安全的文件名（移除特殊字符，转换中文为拼音或使用时间戳）
    const safeName = documentName.value
      .replace(/[^\w\s-]/g, '') // 移除特殊字符
      .replace(/\s+/g, '-')     // 空格转为连字符
      .toLowerCase()
    
    // 如果处理后的名称为空（比如全是中文），使用时间戳
    const finalName = safeName || `document-${Date.now()}`
    const fileName = `${finalName}.${selectedType.value.extension}`
    
    const blob = new Blob([content], { type: 'text/plain' })
    const file = new File([blob], fileName, { type: 'text/plain' })
    
    // 保存原始文件名（包含中文）
    const originalFileName = `${documentName.value}.${selectedType.value.extension}`
    
    // 上传文件
    await uploadFile(file, 'markdown', originalFileName)  // 使用 markdown 类型存储所有文本文件
    
    // 记录日志
    await logActivity('create_document', 'file', null, {
      fileName,
      originalName: documentName.value,
      fileType: selectedType.value.id,
      fileSize: blob.size
    })
    
    alert('文档创建成功！')
    router.push('/dashboard')
  } catch (error) {
    console.error('Save document error:', error)
    alert('保存失败：' + error.message)
  } finally {
    saving.value = false
  }
}

</script>

<style scoped>
.create-content-wrapper {
  min-height: 100vh;
  background-color: #f7fafc;
  padding: 20px;
}

@media (max-width: 768px) {
  .create-content-wrapper {
    padding: 1rem;
    min-height: auto;
  }
}

/* 类型选择 */
.type-selection h2 {
  margin: 0 0 32px 0;
  font-size: 24px;
  font-weight: 600;
  color: #2d3748;
  text-align: center;
}

.type-categories {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.category-section h3 {
  margin: 0 0 16px 0;
  font-size: 18px;
  font-weight: 600;
  color: #2d3748;
}

.type-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
}

.type-card {
  padding: 20px;
  background-color: #ffffff;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.type-card:hover {
  border-color: #4299e1;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(66, 153, 225, 0.2);
}

.type-icon {
  font-size: 48px;
}

.type-info {
  text-align: center;
}

.type-name {
  font-size: 16px;
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 4px;
}

.type-ext {
  font-size: 14px;
  color: #718096;
  font-family: monospace;
}

/* 文档编辑器 */
.document-editor {
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.editor-header {
  padding: 20px 24px;
  border-bottom: 2px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.editor-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.doc-icon {
  font-size: 32px;
}

.doc-name-input {
  flex: 1;
  max-width: 400px;
  padding: 10px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 500;
}

.doc-name-input:focus {
  outline: none;
  border-color: #4299e1;
}

.doc-ext {
  font-size: 16px;
  color: #718096;
  font-family: monospace;
}

.editor-actions {
  display: flex;
  gap: 12px;
}

.btn-change,
.btn-save {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-change {
  background-color: #f7fafc;
  color: #2d3748;
  border: 1px solid #e2e8f0;
}

.btn-change:hover {
  background-color: #edf2f7;
}

.btn-save {
  background-color: #4299e1;
  color: white;
}

.btn-save:hover:not(:disabled) {
  background-color: #3182ce;
}

.btn-save:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

.editor-body {
  min-height: 600px;
}

/* 编辑器工具栏 */
.editor-toolbar {
  padding: 14px 20px;
  background: linear-gradient(to bottom, #ffffff, #fafbfc);
  border-bottom: 1px solid #e1e4e8;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.02);
}

.toolbar-section {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.toolbar-divider {
  width: 1px;
  height: 20px;
  background-color: #d1d5db;
  margin: 0 6px;
}

.toolbar-right {
  display: flex;
  gap: 8px;
}

.toolbar-btn {
  padding: 7px 10px;
  background-color: transparent;
  border: 1px solid transparent;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.15s ease;
  user-select: none;
  color: #374151;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 32px;
  height: 32px;
}

.toolbar-btn:hover {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
}

.toolbar-btn:active {
  transform: scale(0.96);
  background-color: #e5e7eb;
}

.btn-icon {
  font-size: 15px;
  line-height: 1;
}

.btn-view-mode {
  padding: 7px 16px;
  background-color: #f3f4f6;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  transition: all 0.2s ease;
  min-width: 90px;
  white-space: nowrap;
}

.btn-view-mode:hover {
  background-color: #e5e7eb;
  border-color: #9ca3af;
}

.btn-view-mode.mode-edit {
  background-color: #dbeafe;
  border-color: #3b82f6;
  color: #1e40af;
}

.btn-view-mode.mode-preview {
  background-color: #d1fae5;
  border-color: #10b981;
  color: #065f46;
}

.btn-view-mode.mode-split {
  background-color: #fef3c7;
  border-color: #f59e0b;
  color: #92400e;
}

.language-label {
  font-size: 14px;
  font-weight: 500;
  color: #718096;
  margin-right: auto;
}

/* Markdown 编辑器 */
.markdown-editor {
  display: flex;
  flex-direction: column;
}

.editor-split {
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: 600px;
  position: relative;
}

/* 编辑模式 */
.editor-split.mode-edit {
  grid-template-columns: 1fr;
}

.editor-split.mode-edit .markdown-input {
  border-right: none;
}

/* 预览模式 */
.editor-split.mode-preview {
  grid-template-columns: 1fr;
}

/* 分屏模式 */
.editor-split.mode-split {
  grid-template-columns: 1fr 1fr;
}

.markdown-input,
.markdown-preview {
  padding: 32px 40px;
  min-height: 600px;
}

.markdown-input {
  border: none;
  border-right: 1px solid #e5e7eb;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', monospace;
  font-size: 15px;
  line-height: 1.7;
  resize: none;
  color: #1f2937;
  background-color: #ffffff;
}

.markdown-input::placeholder {
  color: #9ca3af;
}

.markdown-input:focus {
  outline: none;
  background-color: #fafbfc;
}

.markdown-preview {
  overflow-y: auto;
  background-color: #fafbfc;
  word-wrap: break-word;
  overflow-wrap: break-word;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
  color: #1f2937;
  line-height: 1.7;
}

.markdown-preview:empty::before {
  content: '👁 实时预览区域';
  color: #9ca3af;
  font-style: italic;
  display: block;
  text-align: center;
  padding-top: 100px;
  font-size: 16px;
}

.markdown-preview :deep(h1) {
  font-size: 2em;
  font-weight: 700;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  color: #111827;
  border-bottom: 2px solid #e5e7eb;
  padding-bottom: 0.3em;
}

.markdown-preview :deep(h2) {
  font-size: 1.5em;
  font-weight: 600;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  color: #1f2937;
}

.markdown-preview :deep(h3) {
  font-size: 1.25em;
  font-weight: 600;
  margin-top: 1.3em;
  margin-bottom: 0.5em;
  color: #374151;
}

.markdown-preview :deep(p) {
  margin: 0.8em 0;
}

.markdown-preview :deep(ul),
.markdown-preview :deep(ol) {
  margin: 0.8em 0;
  padding-left: 2em;
}

.markdown-preview :deep(li) {
  margin: 0.3em 0;
}

.markdown-preview :deep(code) {
  background-color: #f3f4f6;
  color: #dc2626;
  padding: 3px 6px;
  border-radius: 4px;
  font-size: 0.9em;
  font-family: 'Consolas', 'Monaco', monospace;
}

.markdown-preview :deep(pre) {
  background-color: #1e293b;
  color: #e2e8f0;
  padding: 16px 20px;
  border-radius: 8px;
  overflow-x: auto;
  margin: 1em 0;
  border: 1px solid #334155;
}

.markdown-preview :deep(pre code) {
  background: none;
  color: inherit;
  padding: 0;
  border-radius: 0;
}

.markdown-preview :deep(blockquote) {
  border-left: 4px solid #3b82f6;
  padding-left: 1em;
  margin: 1em 0;
  color: #6b7280;
  font-style: italic;
}

.markdown-preview :deep(a) {
  color: #3b82f6;
  text-decoration: none;
}

.markdown-preview :deep(a:hover) {
  text-decoration: underline;
}

.markdown-preview :deep(hr) {
  border: none;
  border-top: 2px solid #e5e7eb;
  margin: 2em 0;
}

.markdown-preview :deep(table) {
  border-collapse: collapse;
  width: 100%;
  margin: 1em 0;
}

.markdown-preview :deep(table th),
.markdown-preview :deep(table td) {
  border: 1px solid #e5e7eb;
  padding: 8px 12px;
  text-align: left;
}

.markdown-preview :deep(table th) {
  background-color: #f9fafb;
  font-weight: 600;
}

/* 文本编辑器 */
.text-input,
.code-input,
.structured-input,
.html-input,
.basic-input {
  width: 100%;
  min-height: 600px;
  padding: 24px;
  border: none;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.6;
  resize: vertical;
}

.text-input:focus,
.code-input:focus,
.structured-input:focus,
.html-input:focus,
.basic-input:focus {
  outline: none;
}

/* 验证消息 */
.validation-message {
  padding: 12px 24px;
  font-size: 14px;
  font-weight: 500;
}

.validation-message.success {
  background-color: #c6f6d5;
  color: #22543d;
}

.validation-message.error {
  background-color: #fed7d7;
  color: #742a2a;
}

/* CSV 编辑器 */
.csv-table {
  padding: 24px;
  overflow-x: auto;
}

.csv-table table {
  width: 100%;
  border-collapse: collapse;
}

.csv-table th,
.csv-table td {
  padding: 8px;
  border: 1px solid #e2e8f0;
}

.csv-table th {
  background-color: #f7fafc;
}

.csv-table input {
  width: 100%;
  padding: 6px;
  border: 1px solid transparent;
  font-size: 14px;
}

.csv-table input:focus {
  outline: none;
  border-color: #4299e1;
  background-color: #ebf8ff;
}

.btn-add {
  padding: 6px 12px;
  background-color: #48bb78;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-add:hover {
  background-color: #38a169;
}

/* HTML 预览 */
.html-preview {
  width: 100%;
  min-height: 600px;
  border: none;
  background-color: #ffffff;
}

.btn-format,
.btn-validate,
.btn-preview {
  padding: 6px 12px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-format:hover,
.btn-validate:hover,
.btn-preview:hover {
  background-color: #3182ce;
}

/* 移动端适配 */
@media (max-width: 768px) {
  /* 编辑器头部 */
  .editor-header {
    padding: 12px 16px;
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  
  .editor-info {
    flex-wrap: wrap;
  }
  
  .doc-icon {
    font-size: 24px;
  }
  
  .doc-name-input {
    max-width: none;
    font-size: 14px;
  }
  
  .editor-actions {
    width: 100%;
    justify-content: stretch;
  }
  
  .btn-change,
  .btn-save {
    flex: 1;
    font-size: 13px;
    padding: 8px 16px;
  }
  
  /* 工具栏 */
  .editor-toolbar {
    padding: 8px 12px;
  }
  
  .toolbar-left {
    flex: 1;
  }
  
  .editor-toolbar button {
    padding: 5px 10px;
    font-size: 13px;
  }
  
  .btn-view-mode {
    min-width: 70px;
    font-size: 13px;
  }
  
  /* 编辑区域 */
  .editor-split {
    min-height: 500px;
  }
  
  /* 移动端默认单栏布局 */
  .editor-split.mode-split {
    grid-template-columns: 1fr;
  }
  
  .editor-split.mode-split .markdown-input {
    border-right: none;
    border-bottom: 1px solid #e2e8f0;
  }
  
  .markdown-input,
  .markdown-preview {
    padding: 16px;
    min-height: 400px;
    font-size: 14px;
  }
  
  .markdown-input {
    min-height: calc(100vh - 250px);
  }
  
  .text-input,
  .code-input,
  .structured-input,
  .html-input,
  .basic-input {
    padding: 16px;
    font-size: 14px;
    min-height: calc(100vh - 250px);
  }
  
  /* 类型选择 */
  .type-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 12px;
  }
  
  .type-card {
    padding: 16px;
  }
  
  .type-icon {
    font-size: 36px;
  }
  
  .type-name {
    font-size: 14px;
  }
  
  .type-ext {
    font-size: 12px;
  }
}

/* 超小屏幕 */
@media (max-width: 480px) {
  .editor-toolbar button {
    padding: 4px 8px;
    font-size: 12px;
  }
  
  .btn-view-mode {
    min-width: 60px;
  }
  
  .type-grid {
    grid-template-columns: 1fr;
  }
}
</style>
