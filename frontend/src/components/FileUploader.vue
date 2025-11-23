<template>
  <div class="file-uploader">
    <div class="upload-area" :class="{ 'drag-over': isDragging }" @drop.prevent="handleDrop" @dragover.prevent="isDragging = true" @dragleave.prevent="isDragging = false">
      <input ref="fileInput" type="file" :accept="acceptTypes" @change="handleFileSelect" class="file-input" />
      
      <div class="upload-content" @click="triggerFileInput">
        <div class="upload-icon">📁</div>
        <p class="upload-text">点击或拖拽文件到此处上传</p>
        <p class="upload-hint">支持 {{ typeText }}</p>
      </div>
    </div>

    <div v-if="selectedFile" class="file-preview">
      <div class="file-info">
        <span class="file-icon">{{ fileIcon }}</span>
        <div class="file-details">
          <p class="file-name">{{ selectedFile.name }}</p>
          <p class="file-size">{{ formatFileSize(selectedFile.size) }}</p>
        </div>
        <button @click="clearFile" class="btn-clear">✕</button>
      </div>
    </div>

    <!-- 上传进度条 -->
    <div v-if="uploading" class="upload-progress">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: uploadProgress + '%' }"></div>
      </div>
      <div class="progress-text">
        <span>上传中...</span>
        <span class="progress-percent">{{ Math.round(uploadProgress) }}%</span>
      </div>
    </div>

    <button @click="upload" :disabled="!selectedFile || uploading" class="btn-upload">
      {{ uploading ? `上传中 ${Math.round(uploadProgress)}%` : '上传文件' }}
    </button>

    <div v-if="error" class="error-message">{{ error }}</div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { uploadFile } from '../api/files'
import { formatFileSize, getFileIcon, validateFileType, validateFileSize } from '../utils/helpers'

const props = defineProps({
  fileType: {
    type: String,
    default: 'all', // 'image', 'markdown', 'all'
  },
  maxSize: {
    type: Number,
    default: 50 * 1024 * 1024, // 50MB
  }
})

const emit = defineEmits(['upload-success', 'upload-error'])

const fileInput = ref(null)
const selectedFile = ref(null)
const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref('')
const isDragging = ref(false)

const acceptTypes = computed(() => {
  if (props.fileType === 'image') return 'image/*'
  if (props.fileType === 'markdown') return '.md,.markdown,text/markdown'
  return 'image/*,.md,.markdown'
})

const typeText = computed(() => {
  if (props.fileType === 'image') return '图片文件'
  if (props.fileType === 'markdown') return 'Markdown 文件'
  return '图片和 Markdown 文件'
})

const fileIcon = computed(() => {
  if (!selectedFile.value) return ''
  const name = selectedFile.value.name.toLowerCase()
  if (name.endsWith('.md') || name.endsWith('.markdown')) return '📝'
  return '🖼️'
})

function triggerFileInput() {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

function handleFileSelect(event) {
  const file = event.target.files[0]
  if (file) {
    validateAndSetFile(file)
  }
}

function handleDrop(event) {
  isDragging.value = false
  const file = event.dataTransfer.files[0]
  if (file) {
    validateAndSetFile(file)
  }
}

function validateAndSetFile(file) {
  error.value = ''

  // 验证文件大小
  if (!validateFileSize(file, props.maxSize)) {
    error.value = `文件大小不能超过 ${formatFileSize(props.maxSize)}`
    return
  }

  // 验证文件类型
  const allowedTypes = props.fileType === 'image' 
    ? ['image/'] 
    : props.fileType === 'markdown' 
    ? ['.md', '.markdown'] 
    : ['image/', '.md', '.markdown']

  if (!validateFileType(file, allowedTypes)) {
    error.value = '不支持的文件类型'
    return
  }

  selectedFile.value = file
}

function clearFile() {
  selectedFile.value = null
  error.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

async function upload() {
  if (!selectedFile.value || uploading.value) return

  try {
    uploading.value = true
    uploadProgress.value = 0
    error.value = ''

    // 判断文件类型
    const type = selectedFile.value.name.toLowerCase().match(/\.(md|markdown)$/) 
      ? 'markdown' 
      : 'images'

    // 上传文件并监听进度
    await uploadFile(selectedFile.value, type, null, (progress) => {
      uploadProgress.value = progress
    })

    emit('upload-success', selectedFile.value)
    clearFile()
  } catch (err) {
    error.value = err.message || '上传失败，请重试'
    emit('upload-error', err)
  } finally {
    uploading.value = false
    uploadProgress.value = 0
  }
}

</script>

<style scoped>
.file-uploader {
  width: 100%;
  max-width: 600px;
  margin: 0 auto;
}

.upload-area {
  border: 2px dashed #cbd5e0;
  border-radius: 8px;
  padding: 40px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  background-color: #f7fafc;
}

.upload-area:hover,
.upload-area.drag-over {
  border-color: #4299e1;
  background-color: #ebf8ff;
}

.file-input {
  display: none;
}

.upload-content {
  cursor: pointer;
}

.upload-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.upload-text {
  font-size: 16px;
  font-weight: 500;
  color: #2d3748;
  margin-bottom: 8px;
}

.upload-hint {
  font-size: 14px;
  color: #718096;
}

.file-preview {
  margin-top: 20px;
  padding: 16px;
  background-color: #f7fafc;
  border-radius: 8px;
}

.file-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.file-icon {
  font-size: 32px;
}

.file-details {
  flex: 1;
  text-align: left;
}

.file-name {
  font-weight: 500;
  color: #2d3748;
  margin: 0 0 4px 0;
}

.file-size {
  font-size: 14px;
  color: #718096;
  margin: 0;
}

.btn-clear {
  padding: 8px;
  background: none;
  border: none;
  color: #e53e3e;
  cursor: pointer;
  font-size: 20px;
  line-height: 1;
}

.btn-clear:hover {
  color: #c53030;
}

.btn-upload {
  width: 100%;
  margin-top: 20px;
  padding: 12px 24px;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.btn-upload:hover:not(:disabled) {
  background-color: #3182ce;
}

.btn-upload:disabled {
  background-color: #cbd5e0;
  cursor: not-allowed;
}

.upload-progress {
  margin-top: 20px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background-color: #e2e8f0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4299e1 0%, #667eea 100%);
  border-radius: 4px;
  transition: width 0.3s ease;
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% {
    background-position: -100% 0;
  }
  100% {
    background-position: 100% 0;
  }
}

.progress-text {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: #4a5568;
}

.progress-percent {
  font-weight: 600;
  color: #4299e1;
}

.error-message {
  margin-top: 12px;
  padding: 12px;
  background-color: #fff5f5;
  color: #e53e3e;
  border-radius: 8px;
  font-size: 14px;
}

/* 移动端优化 */
@media (max-width: 768px) {
  .file-uploader {
    max-width: 100%;
  }
  
  .upload-area {
    padding: 2rem 1rem;
  }
  
  .upload-icon {
    font-size: 3rem;
  }
  
  .upload-text {
    font-size: 0.875rem;
  }
  
  .upload-hint {
    font-size: 0.75rem;
  }
  
  .file-preview {
    margin-top: 1rem;
    padding: 1rem;
  }
  
  .file-icon {
    font-size: 2rem;
  }
  
  .file-name {
    font-size: 0.875rem;
  }
  
  .file-size {
    font-size: 0.75rem;
  }
  
  .upload-progress {
    margin-top: 1rem;
  }
  
  .progress-bar {
    height: 10px;
  }
  
  .progress-text {
    font-size: 1rem;
  }
  
  .btn-upload {
    padding: 1rem;
    font-size: 1rem;
  }
}
</style>
