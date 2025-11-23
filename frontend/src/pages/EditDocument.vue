<template>
  <div class="edit-document-page">
    <div class="edit-header">
      <button @click="goBack" class="btn-back">← 返回</button>
      <div class="file-info">
        <span class="file-icon">{{ getFileIcon() }}</span>
        <h1>{{ file?.original_name || file?.name || '加载中...' }}</h1>
      </div>
      <div class="header-actions">
        <button @click="saveDocument" :disabled="saving" class="btn-save">
          {{ saving ? '保存中...' : '💾 保存' }}
        </button>
      </div>
    </div>

    <div class="edit-content">
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>

      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <button @click="loadFile" class="btn-retry">重试</button>
      </div>

      <div v-else class="editor-container">
        <!-- Markdown 编辑器 -->
        <div v-if="isMarkdown" class="markdown-editor">
          <div class="editor-split">
            <textarea 
              v-model="content" 
              @input="handleInput"
              placeholder="编辑 Markdown..."
              class="markdown-input"
            ></textarea>
            <div class="markdown-preview" v-html="markdownPreview"></div>
          </div>
        </div>

        <!-- 纯文本编辑器 -->
        <textarea 
          v-else
          v-model="content" 
          @input="handleInput"
          placeholder="编辑文档..."
          class="text-editor"
        ></textarea>
      </div>
    </div>

    <!-- 自动保存提示 -->
    <div v-if="autoSaveStatus" class="auto-save-toast" :class="autoSaveStatus">
      {{ autoSaveMessage }}
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getFileById, getSignedUrl } from '../api/files'
import { supabase } from '../api/supabase'
import { renderMarkdown } from '../utils/markdown'
import { debounce } from '../utils/helpers'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const file = ref(null)
const content = ref('')
const originalContent = ref('')
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const autoSaveStatus = ref('')
const autoSaveMessage = ref('')

const isMarkdown = computed(() => {
  return file.value?.type === 'markdown' || file.value?.name?.endsWith('.md')
})

const markdownPreview = computed(() => {
  if (isMarkdown.value) {
    return renderMarkdown(content.value)
  }
  return ''
})

onMounted(async () => {
  await loadFile()
})

async function loadFile() {
  try {
    loading.value = true
    error.value = ''

    // 获取文件信息
    file.value = await getFileById(route.params.id)

    // 获取文件内容
    const url = await getSignedUrl(file.value.path)
    const response = await axios.get(url)
    content.value = response.data
    originalContent.value = response.data
  } catch (err) {
    console.error('Load file error:', err)
    error.value = '加载文件失败：' + err.message
  } finally {
    loading.value = false
  }
}

// 防抖的自动保存
const debouncedSave = debounce(async () => {
  if (content.value === originalContent.value) return
  
  try {
    autoSaveStatus.value = 'saving'
    autoSaveMessage.value = '保存中...'
    
    await saveToStorage()
    
    originalContent.value = content.value
    autoSaveStatus.value = 'success'
    autoSaveMessage.value = '✓ 已保存'
    
    setTimeout(() => {
      autoSaveStatus.value = ''
    }, 2000)
  } catch (err) {
    autoSaveStatus.value = 'error'
    autoSaveMessage.value = '✗ 保存失败'
    console.error('Auto save error:', err)
  }
}, 2000)

function handleInput() {
  debouncedSave()
}

async function saveDocument() {
  if (saving.value) return
  
  try {
    saving.value = true
    await saveToStorage()
    originalContent.value = content.value
    alert('保存成功！')
  } catch (err) {
    alert('保存失败：' + err.message)
  } finally {
    saving.value = false
  }
}

async function saveToStorage() {
  // 创建新的文件内容
  const blob = new Blob([content.value], { type: 'text/plain' })
  const newFile = new File([blob], file.value.name, { type: 'text/plain' })
  
  // 上传到 Storage（覆盖原文件）
  const { error: uploadError } = await supabase.storage
    .from('private-files')
    .update(file.value.path, newFile, {
      cacheControl: '0',
      upsert: true
    })
  
  if (uploadError) throw uploadError
}

function goBack() {
  if (content.value !== originalContent.value) {
    if (!confirm('有未保存的更改，确定要离开吗？')) {
      return
    }
  }
  router.back()
}

function getFileIcon() {
  if (isMarkdown.value) return '📝'
  return '📄'
}

// 页面离开前提示
onUnmounted(() => {
  if (content.value !== originalContent.value) {
    // 浏览器会显示默认的离开确认对话框
  }
})

</script>

<style scoped>
.edit-document-page {
  min-height: 100vh;
  background-color: #f7fafc;
  display: flex;
  flex-direction: column;
}

.edit-header {
  background-color: #ffffff;
  border-bottom: 2px solid #e2e8f0;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  gap: 20px;
  position: sticky;
  top: 0;
  z-index: 10;
}

.btn-back {
  padding: 8px 16px;
  background-color: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s ease;
}

.btn-back:hover {
  background-color: #edf2f7;
}

.file-info {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 12px;
}

.file-icon {
  font-size: 28px;
}

.file-info h1 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #2d3748;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.btn-save {
  padding: 10px 20px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-save:hover:not(:disabled) {
  background-color: #3182ce;
}

.btn-save:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

.edit-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.loading,
.error {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid #e2e8f0;
  border-top-color: #4299e1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading p {
  margin-top: 20px;
  color: #718096;
}

.error {
  color: #e53e3e;
}

.btn-retry {
  margin-top: 20px;
  padding: 10px 20px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.editor-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  background-color: #ffffff;
}

.markdown-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.editor-split {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: calc(100vh - 80px);
}

.markdown-input,
.text-editor {
  width: 100%;
  padding: 24px;
  border: none;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 14px;
  line-height: 1.6;
  resize: none;
}

.markdown-input {
  border-right: 1px solid #e2e8f0;
}

.markdown-input:focus,
.text-editor:focus {
  outline: none;
}

.text-editor {
  min-height: calc(100vh - 80px);
}

.markdown-preview {
  padding: 24px;
  overflow-y: auto;
  background-color: #f7fafc;
}

.markdown-preview :deep(h1),
.markdown-preview :deep(h2),
.markdown-preview :deep(h3) {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  font-weight: 600;
}

.markdown-preview :deep(code) {
  background-color: #edf2f7;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.9em;
}

.markdown-preview :deep(pre) {
  background-color: #2d3748;
  color: #f7fafc;
  padding: 16px;
  border-radius: 6px;
  overflow-x: auto;
}

.auto-save-toast {
  position: fixed;
  bottom: 20px;
  right: 20px;
  padding: 12px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  animation: slideIn 0.3s ease;
  z-index: 1000;
}

@keyframes slideIn {
  from {
    transform: translateY(100px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.auto-save-toast.saving {
  background-color: #ebf8ff;
  color: #2c5282;
}

.auto-save-toast.success {
  background-color: #c6f6d5;
  color: #22543d;
}

.auto-save-toast.error {
  background-color: #fed7d7;
  color: #742a2a;
}
</style>
