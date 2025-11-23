<template>
  <div class="share-page">
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error-container">
      <div class="error-icon">❌</div>
      <h2>{{ error }}</h2>
      <button @click="$router.push('/')" class="btn-home">返回首页</button>
    </div>

    <div v-else class="share-container">
      <div class="share-header">
        <div class="file-icon-large">{{ getFileIcon(fileData.type) }}</div>
        <h1>{{ fileData.original_name || fileData.name }}</h1>
        <div class="file-meta">
          <span>{{ formatFileSize(fileData.size) }}</span>
          <span class="separator">•</span>
          <span>{{ formatDateTime(fileData.created_at) }}</span>
        </div>
      </div>

      <div class="share-actions">
        <button @click="downloadFile" class="btn-download">
          ⬇️ 下载文件
        </button>
        <button v-if="fileData.type === 'markdown'" @click="showPreview = !showPreview" class="btn-preview">
          {{ showPreview ? '隐藏预览' : '👁️ 预览' }}
        </button>
      </div>

      <div v-if="showPreview && fileData.type === 'markdown'" class="preview-container">
        <div v-if="loadingPreview" class="loading-preview">加载预览中...</div>
        <div v-else class="markdown-content prose" v-html="markdownHtml"></div>
      </div>

      <div class="share-info">
        <p>📊 已下载 {{ shareData.download_count }} 次</p>
        <p v-if="shareData.expires_at">⏰ 过期时间：{{ formatDateTime(shareData.expires_at) }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getShareByToken, incrementShareDownload } from '../api/shares'
import { getSignedUrl } from '../api/files'
import { formatFileSize, formatDateTime, getFileIcon } from '../utils/helpers'
import { renderMarkdown } from '../utils/markdown'
import { downloadFile as downloadFileUtil, isMobileDevice } from '../utils/download'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const error = ref('')
const shareData = ref(null)
const fileData = ref(null)
const showPreview = ref(false)
const loadingPreview = ref(false)
const markdownHtml = ref('')

onMounted(async () => {
  await loadShare()
})

async function loadShare() {
  try {
    loading.value = true
    error.value = ''

    const token = route.params.token
    const data = await getShareByToken(token)
    
    shareData.value = data
    fileData.value = data.files
  } catch (err) {
    error.value = err.message || '分享链接无效或已过期'
  } finally {
    loading.value = false
  }
}

async function downloadFile() {
  try {
    const url = await getSignedUrl(fileData.value.path)
    const fileName = fileData.value.original_name || fileData.value.name
    
    // 移动端提示
    if (isMobileDevice() && fileData.value.type === 'images') {
      const tip = '提示：图片将在新标签页打开，长按图片可保存到相册 📱'
      if (!confirm(tip + '\n\n点击确定继续')) {
        return
      }
    }
    
    // 增加下载次数
    await incrementShareDownload(shareData.value.id)
    
    // 下载文件
    await downloadFileUtil(url, fileName)
    
    // 更新下载次数显示
    shareData.value.download_count++
  } catch (err) {
    alert('下载失败：' + err.message)
  }
}

// 监听预览状态变化
async function loadPreview() {
  if (loadingPreview.value || markdownHtml.value) return
  
  try {
    loadingPreview.value = true
    const url = await getSignedUrl(fileData.value.path)
    const response = await axios.get(url)
    markdownHtml.value = renderMarkdown(response.data)
  } catch (err) {
    alert('加载预览失败：' + err.message)
  } finally {
    loadingPreview.value = false
  }
}

// 当显示预览时加载内容
const unwatchPreview = () => {
  if (showPreview.value) {
    loadPreview()
  }
}

// 监听 showPreview 变化
import { watch } from 'vue'
watch(showPreview, unwatchPreview)

</script>

<style scoped>
.share-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.loading {
  text-align: center;
  color: white;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-container {
  background-color: white;
  padding: 60px 40px;
  border-radius: 16px;
  text-align: center;
  max-width: 500px;
}

.error-icon {
  font-size: 64px;
  margin-bottom: 20px;
}

.error-container h2 {
  margin: 0 0 30px 0;
  color: #e53e3e;
}

.btn-home {
  padding: 12px 32px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-home:hover {
  background-color: #3182ce;
}

.share-container {
  background-color: white;
  border-radius: 16px;
  padding: 40px;
  max-width: 800px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.share-header {
  text-align: center;
  margin-bottom: 32px;
  padding-bottom: 32px;
  border-bottom: 2px solid #e2e8f0;
}

.file-icon-large {
  font-size: 80px;
  margin-bottom: 20px;
}

.share-header h1 {
  margin: 0 0 12px 0;
  font-size: 28px;
  font-weight: 600;
  color: #2d3748;
  word-break: break-word;
}

.file-meta {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  font-size: 14px;
  color: #718096;
}

.separator {
  color: #cbd5e0;
}

.share-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-bottom: 32px;
}

.btn-download,
.btn-preview {
  padding: 14px 32px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.btn-download {
  background-color: #48bb78;
  color: white;
}

.btn-download:hover {
  background-color: #38a169;
}

.btn-preview {
  background-color: #4299e1;
  color: white;
}

.btn-preview:hover {
  background-color: #3182ce;
}

.preview-container {
  margin-bottom: 32px;
  padding: 24px;
  background-color: #f7fafc;
  border-radius: 8px;
  max-height: 600px;
  overflow-y: auto;
}

.loading-preview {
  text-align: center;
  padding: 40px;
  color: #718096;
}

.markdown-content {
  color: #2d3748;
  line-height: 1.75;
}

.prose :deep(h1),
.prose :deep(h2),
.prose :deep(h3) {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  font-weight: 600;
}

.prose :deep(code) {
  background-color: #edf2f7;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.9em;
}

.prose :deep(pre) {
  background-color: #2d3748;
  color: #f7fafc;
  padding: 16px;
  border-radius: 6px;
  overflow-x: auto;
}

.share-info {
  text-align: center;
  padding-top: 24px;
  border-top: 1px solid #e2e8f0;
  color: #718096;
  font-size: 14px;
}

.share-info p {
  margin: 8px 0;
}

/* 移动端优化 */
@media (max-width: 768px) {
  .share-page {
    padding: 1rem;
  }
  
  .share-container {
    padding: 1.5rem;
    border-radius: var(--radius-lg);
  }
  
  .share-header {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
  }
  
  .file-icon-large {
    font-size: 4rem;
    margin-bottom: 1rem;
  }
  
  .share-header h1 {
    font-size: 1.25rem;
  }
  
  .file-meta {
    font-size: 0.75rem;
    flex-wrap: wrap;
  }
  
  .share-actions {
    flex-direction: column;
    margin-bottom: 1.5rem;
  }
  
  .btn-download,
  .btn-preview {
    width: 100%;
    padding: 1rem;
  }
  
  .preview-container {
    padding: 1rem;
    max-height: 400px;
  }
  
  .error-container {
    padding: 2rem 1.5rem;
    margin: 1rem;
  }
  
  .error-icon {
    font-size: 3rem;
  }
  
  .error-container h2 {
    font-size: 1.25rem;
  }
  
  .btn-home {
    padding: 0.875rem 2rem;
  }
}
</style>
