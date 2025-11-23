<template>
  <div class="file-list">
    <!-- 视图切换工具栏 -->
    <div v-if="!loading && files.length > 0" class="view-toolbar">
      <div class="view-modes">
        <button 
          @click="changeViewMode('grid')"
          :class="['view-btn', { active: currentViewMode === 'grid' }]"
          title="网格视图"
        >
          <span class="view-icon">▦</span>
        </button>
        <button 
          @click="changeViewMode('list')"
          :class="['view-btn', { active: currentViewMode === 'list' }]"
          title="列表视图"
        >
          <span class="view-icon">☰</span>
        </button>
        <button 
          @click="changeViewMode('compact')"
          :class="['view-btn', { active: currentViewMode === 'compact' }]"
          title="紧凑视图"
        >
          <span class="view-icon">▤</span>
        </button>
      </div>
      <div class="file-count">
        {{ filteredFiles.length }} 个文件
      </div>
    </div>

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error">{{ error }}</div>

    <div v-else-if="files.length === 0" class="empty">
      <div class="empty-icon">📂</div>
      <p>暂无文件</p>
      <p class="empty-hint">上传您的第一个文件开始使用</p>
    </div>

    <!-- 网格视图 -->
    <div v-else-if="currentViewMode === 'grid'" class="file-grid">
      <div v-for="file in filteredFiles" :key="file.id" class="file-card">
        <!-- 文件预览区域 -->
        <div class="file-thumbnail" @click="handleFileClick(file)">
          <img 
            v-if="file.type === 'images' && file.thumbnail_url" 
            :src="file.thumbnail_url" 
            :alt="file.name"
            class="thumbnail-image"
            @error="handleImageError"
          />
          <div v-else class="file-icon-wrapper">
            <div class="file-icon-bg" :class="`type-${file.type}`"></div>
            <span class="file-icon">{{ getFileIcon(file.type) }}</span>
          </div>
          
          <!-- 悬停遮罩 -->
          <div class="hover-overlay">
            <button @click.stop="handleFileClick(file)" class="quick-action">
              <span>{{ file.type === 'markdown' ? '👁️ 预览' : '⬇️ 下载' }}</span>
            </button>
          </div>
        </div>
        
        <!-- 文件信息 -->
        <div class="file-details">
          <h3 class="file-name" :title="file.original_name || file.name">
            {{ file.original_name || file.name }}
          </h3>
          <p class="file-meta">
            <span class="file-size">{{ formatFileSize(file.size) }}</span>
            <span class="separator">•</span>
            <span class="file-date">{{ formatDateTime(file.created_at) }}</span>
          </p>
        </div>

        <!-- 操作按钮 -->
        <div class="file-actions">
          <button @click="editFile(file)" class="action-btn" title="编辑">
            <span class="action-icon">✏️</span>
          </button>
          <button @click="shareFile(file)" class="action-btn" title="分享">
            <span class="action-icon">🔗</span>
          </button>
          <button @click="download(file)" class="action-btn" title="下载">
            <span class="action-icon">⬇️</span>
          </button>
          <button @click="confirmDelete(file)" class="action-btn action-delete" title="删除">
            <span class="action-icon">🗑️</span>
          </button>
        </div>
      </div>
    </div>

    <!-- 列表视图 -->
    <div v-else-if="currentViewMode === 'list'" class="file-list-view">
      <div v-for="file in filteredFiles" :key="file.id" class="file-row">
        <div class="file-row-preview" @click="handleFileClick(file)">
          <img 
            v-if="file.type === 'images' && file.thumbnail_url" 
            :src="file.thumbnail_url" 
            :alt="file.name"
            class="row-thumbnail"
            @error="handleImageError"
          />
          <div v-else class="row-icon">{{ getFileIcon(file.type) }}</div>
        </div>
        
        <div class="file-row-info" @click="handleFileClick(file)">
          <h3 class="file-row-name">{{ file.original_name || file.name }}</h3>
          <p class="file-row-meta">
            <span>{{ formatFileSize(file.size) }}</span>
            <span class="separator">•</span>
            <span>{{ formatDateTime(file.created_at) }}</span>
          </p>
        </div>

        <div class="file-row-actions">
          <button @click="shareFile(file)" class="row-action-btn" title="分享">
            🔗
          </button>
          <button @click="download(file)" class="row-action-btn" title="下载">
            ⬇️
          </button>
          <button @click="confirmDelete(file)" class="row-action-btn row-delete" title="删除">
            🗑️
          </button>
        </div>
      </div>
    </div>

    <!-- 紧凑视图 -->
    <div v-else-if="currentViewMode === 'compact'" class="file-compact-view">
      <div v-for="file in filteredFiles" :key="file.id" class="file-compact-row">
        <div class="compact-icon">{{ getFileIcon(file.type) }}</div>
        <div class="compact-info" @click="handleFileClick(file)">
          <span class="compact-name">{{ file.original_name || file.name }}</span>
          <span class="compact-size">{{ formatFileSize(file.size) }}</span>
        </div>
        <div class="compact-actions">
          <button @click="download(file)" class="compact-btn">⬇️</button>
          <button @click="confirmDelete(file)" class="compact-btn compact-delete">🗑️</button>
        </div>
      </div>
    </div>
    
    <!-- 分享弹窗 -->
    <ShareDialog 
      v-model:show="showShareDialog" 
      :share-link="currentShareLink" 
    />
    
    <!-- 图片预览 -->
    <ImagePreview
      v-model:show="showImagePreview"
      :image-url="currentImageUrl"
      :file-name="currentImageName"
      :file-size="currentImageSize"
      :file-date="currentImageDate"
      @download="handleImageDownload"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getFiles, getSignedUrl, deleteFile } from '../api/files'
import { createFileShare } from '../api/shares'
import { formatFileSize, formatDateTime, getFileIcon } from '../utils/helpers'
import { downloadFile, isMobileDevice } from '../utils/download'
import ShareDialog from './ShareDialog.vue'
import ImagePreview from './ImagePreview.vue'

const props = defineProps({
  search: {
    type: String,
    default: ''
  },
  filter: {
    type: String,
    default: 'all'
  },
  viewMode: {
    type: String,
    default: 'grid' // grid, list, compact
  }
})

const emit = defineEmits(['files-loaded', 'view-mode-change'])

const router = useRouter()

const files = ref([])
const loading = ref(true)
const error = ref('')
const currentViewMode = ref(props.viewMode)

// 分享弹窗状态
const showShareDialog = ref(false)
const currentShareLink = ref('')

// 图片预览状态
const showImagePreview = ref(false)
const currentImageUrl = ref('')
const currentImageName = ref('')
const currentImageSize = ref('')
const currentImageDate = ref('')
const currentImageFile = ref(null)

const filteredFiles = computed(() => {
  let result = files.value
  
  // 类型过滤
  if (props.filter !== 'all') {
    result = result.filter(file => file.type === props.filter)
  }
  
  // 搜索过滤
  if (props.search) {
    const query = props.search.toLowerCase()
    result = result.filter(file => {
      const name = (file.original_name || file.name).toLowerCase()
      return name.includes(query)
    })
  }
  
  return result
})

onMounted(async () => {
  // 从 localStorage 恢复视图模式
  const savedMode = localStorage.getItem('fileViewMode')
  if (savedMode) {
    currentViewMode.value = savedMode
  }
  
  await loadFiles()
})

async function loadFiles() {
  try {
    loading.value = true
    error.value = ''
    const fileList = await getFiles()
    
    // 为图片文件生成缩略图 URL
    for (const file of fileList) {
      if (file.type === 'images') {
        try {
          file.thumbnail_url = await getSignedUrl(file.path)
        } catch (err) {
          console.error('Failed to load thumbnail:', err)
        }
      }
    }
    
    files.value = fileList
    emit('files-loaded', fileList)
  } catch (err) {
    error.value = '加载文件列表失败'
    console.error(err)
  } finally {
    loading.value = false
  }
}

function handleImageError(event) {
  event.target.style.display = 'none'
}

async function download(file) {
  try {
    const url = await getSignedUrl(file.path)
    const fileName = file.original_name || file.name
    
    // 移动端提示
    if (isMobileDevice() && file.type === 'images') {
      const tip = '提示：图片将在新标签页打开，长按图片可保存到相册 📱'
      if (!confirm(tip + '\n\n点击确定继续')) {
        return
      }
    }
    
    await downloadFile(url, fileName)
  } catch (err) {
    alert('下载失败：' + err.message)
  }
}

function editFile(file) {
  router.push(`/edit/${file.id}`)
}

function preview(file) {
  router.push(`/preview/${file.id}`)
}

async function handleFileClick(file) {
  const isMobile = isMobileDevice()
  
  // 移动端优先预览
  if (isMobile) {
    if (file.type === 'images') {
      // 图片：显示预览
      await previewImage(file)
    } else if (file.type === 'markdown') {
      // Markdown：跳转预览页面
      preview(file)
    } else {
      // 其他文件：直接下载
      download(file)
    }
  } else {
    // 桌面端：保持原逻辑
    if (file.type === 'markdown') {
      preview(file)
    } else if (file.type === 'images') {
      // 桌面端图片也可以预览
      await previewImage(file)
    } else {
      download(file)
    }
  }
}

async function previewImage(file) {
  try {
    const url = await getSignedUrl(file.path)
    currentImageUrl.value = url
    currentImageName.value = file.original_name || file.name
    currentImageSize.value = formatFileSize(file.size)
    currentImageDate.value = formatDateTime(file.created_at)
    currentImageFile.value = file
    showImagePreview.value = true
  } catch (err) {
    console.error('Preview failed:', err)
    alert('预览失败：' + err.message)
  }
}

function handleImageDownload() {
  // 图片预览中点击下载
  console.log('Image downloaded from preview')
}

function changeViewMode(mode) {
  currentViewMode.value = mode
  emit('view-mode-change', mode)
  // 保存到 localStorage
  localStorage.setItem('fileViewMode', mode)
}

async function shareFile(file) {
  try {
    const share = await createFileShare(file.id)
    const baseUrl = window.location.origin
    const shareLink = `${baseUrl}/share/${share.share_token}`
    
    // 先显示弹窗（包含分享链接）
    currentShareLink.value = shareLink
    showShareDialog.value = true
    
    // 尝试复制到剪贴板（移动端可能失败，但不影响弹窗显示）
    try {
      // 检查是否支持 Web Share API（移动端原生分享）
      if (navigator.share && isMobileDevice()) {
        // 移动端优先使用原生分享
        await navigator.share({
          title: `分享文件: ${file.original_name || file.name}`,
          text: `查看我分享的文件`,
          url: shareLink
        })
      } else if (navigator.clipboard && navigator.clipboard.writeText) {
        // 桌面端或支持 Clipboard API
        await navigator.clipboard.writeText(shareLink)
      } else {
        // 回退方案：使用传统方法
        fallbackCopyToClipboard(shareLink)
      }
    } catch (copyErr) {
      console.log('Copy to clipboard failed:', copyErr)
      // 复制失败不影响分享功能，用户仍可以手动复制
    }
  } catch (err) {
    console.error('Share error:', err)
    alert('❌ 创建分享失败：' + err.message)
  }
}

// 回退的复制方法
function fallbackCopyToClipboard(text) {
  const textArea = document.createElement('textarea')
  textArea.value = text
  textArea.style.position = 'fixed'
  textArea.style.left = '-999999px'
  textArea.style.top = '-999999px'
  document.body.appendChild(textArea)
  textArea.focus()
  textArea.select()
  
  try {
    document.execCommand('copy')
    textArea.remove()
  } catch (err) {
    console.error('Fallback copy failed:', err)
    textArea.remove()
  }
}

async function confirmDelete(file) {
  if (!confirm(`确定要删除 "${file.name}" 吗？`)) {
    return
  }

  try {
    await deleteFile(file.id, file.path)
    await loadFiles()
  } catch (err) {
    alert('删除失败：' + err.message)
  }
}

defineExpose({
  loadFiles
})

</script>

<style scoped>
.file-list {
  width: 100%;
}

/* 加载状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 20px;
  gap: 1rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid var(--gray-200);
  border-top-color: var(--primary-500);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading p {
  color: var(--gray-600);
  font-size: 1rem;
}

/* 错误和空状态 */
.error,
.empty {
  text-align: center;
  padding: 80px 20px;
  color: var(--gray-600);
}

.empty-icon {
  font-size: 80px;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.empty p {
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--gray-700);
  margin-bottom: 0.5rem;
}

.empty-hint {
  font-size: 0.875rem;
  color: var(--gray-500);
}

.error {
  color: var(--error);
}

/* 文件网格 */
.file-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 1.5rem;
  animation: fadeIn 0.5s ease;
}

/* 文件卡片 */
.file-card {
  background: white;
  border-radius: var(--radius-xl);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
  border: 1px solid var(--gray-200);
}

.file-card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-4px);
  border-color: var(--primary-300);
}

/* 缩略图区域 */
.file-thumbnail {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  cursor: pointer;
}

.thumbnail-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: var(--transition);
}

.file-card:hover .thumbnail-image {
  transform: scale(1.05);
}

/* 文件图标 */
.file-icon-wrapper {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.file-icon-bg {
  position: absolute;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  opacity: 0.2;
}

.file-icon-bg.type-images {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.file-icon-bg.type-markdown {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.file-icon {
  font-size: 4rem;
  position: relative;
  z-index: 1;
}

/* 悬停遮罩 */
.hover-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: var(--transition);
}

.file-card:hover .hover-overlay {
  opacity: 1;
}

.quick-action {
  padding: 0.75rem 1.5rem;
  background: white;
  border: none;
  border-radius: var(--radius-full);
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--gray-900);
  cursor: pointer;
  transition: var(--transition);
  box-shadow: var(--shadow-lg);
}

.quick-action:hover {
  transform: scale(1.05);
  box-shadow: var(--shadow-xl);
}

/* 文件详情 */
.file-details {
  padding: 1rem;
  border-bottom: 1px solid var(--gray-100);
}

.file-name {
  margin: 0 0 0.5rem 0;
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--gray-900);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.4;
}

.file-meta {
  margin: 0;
  font-size: 0.8125rem;
  color: var(--gray-500);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.separator {
  color: var(--gray-300);
}

/* 操作按钮 */
.file-actions {
  display: flex;
  padding: 0.75rem;
  gap: 0.5rem;
  background: var(--gray-50);
}

.action-btn {
  flex: 1;
  padding: 0.5rem;
  background: white;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: var(--transition);
  display: flex;
  align-items: center;
  justify-content: center;
}

.action-btn:hover {
  background: var(--gray-100);
  border-color: var(--gray-300);
  transform: translateY(-2px);
}

.action-btn:active {
  transform: translateY(0);
}

.action-icon {
  font-size: 1.125rem;
}

.action-delete:hover {
  background: #fff5f5;
  border-color: #fecaca;
}

/* 视图工具栏 */
.view-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.5rem;
  padding: 0.75rem 1rem;
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.view-modes {
  display: flex;
  gap: 0.5rem;
  background: var(--gray-100);
  padding: 0.25rem;
  border-radius: var(--radius-md);
}

.view-btn {
  padding: 0.5rem 0.75rem;
  background: transparent;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: var(--transition);
  color: var(--gray-600);
}

.view-btn:hover {
  background: var(--gray-200);
  color: var(--gray-900);
}

.view-btn.active {
  background: white;
  color: var(--primary-600);
  box-shadow: var(--shadow-sm);
}

.view-icon {
  font-size: 1.25rem;
  display: block;
}

.file-count {
  font-size: 0.875rem;
  color: var(--gray-600);
  font-weight: 500;
}

/* 列表视图 */
.file-list-view {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.file-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: white;
  border-radius: var(--radius-lg);
  border: 1px solid var(--gray-200);
  transition: var(--transition);
}

.file-row:hover {
  border-color: var(--primary-300);
  box-shadow: var(--shadow-md);
}

.file-row-preview {
  width: 60px;
  height: 60px;
  flex-shrink: 0;
  border-radius: var(--radius-md);
  overflow: hidden;
  background: var(--gray-100);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.row-thumbnail {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.row-icon {
  font-size: 2rem;
}

.file-row-info {
  flex: 1;
  min-width: 0;
  cursor: pointer;
}

.file-row-name {
  margin: 0 0 0.25rem 0;
  font-size: 1rem;
  font-weight: 600;
  color: var(--gray-900);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-row-meta {
  margin: 0;
  font-size: 0.875rem;
  color: var(--gray-500);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.file-row-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.row-action-btn {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--gray-100);
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  font-size: 1.125rem;
  transition: var(--transition);
}

.row-action-btn:hover {
  background: var(--gray-200);
  transform: scale(1.05);
}

.row-delete:hover {
  background: #fee2e2;
}

/* 紧凑视图 */
.file-compact-view {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.file-compact-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: white;
  border-radius: var(--radius-md);
  border: 1px solid var(--gray-200);
  transition: var(--transition);
}

.file-compact-row:hover {
  background: var(--gray-50);
  border-color: var(--gray-300);
}

.compact-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.compact-info {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
}

.compact-name {
  flex: 1;
  font-size: 0.9375rem;
  font-weight: 500;
  color: var(--gray-900);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.compact-size {
  font-size: 0.8125rem;
  color: var(--gray-500);
  flex-shrink: 0;
}

.compact-actions {
  display: flex;
  gap: 0.25rem;
  flex-shrink: 0;
}

.compact-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  font-size: 1rem;
  transition: var(--transition);
}

.compact-btn:hover {
  background: var(--gray-200);
}

.compact-delete:hover {
  background: #fee2e2;
}

/* 响应式网格 */
@media (max-width: 1200px) {
  .file-grid {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 1rem;
  }
}

@media (max-width: 768px) {
  .view-toolbar {
    padding: 0.5rem 0.75rem;
    margin-bottom: 1rem;
  }
  
  .view-modes {
    padding: 0.125rem;
  }
  
  .view-btn {
    padding: 0.375rem 0.625rem;
  }
  
  .view-icon {
    font-size: 1.125rem;
  }
  
  .file-count {
    font-size: 0.8125rem;
  }
  
  /* 移动端列表视图优化 */
  .file-row {
    padding: 12px;
    gap: 12px;
    border-radius: 12px;
  }
  
  .file-row-preview {
    width: 60px;
    height: 60px;
    border-radius: 8px;
    overflow: hidden;
  }
  
  .row-thumbnail {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  
  .row-icon {
    font-size: 2rem;
  }
  
  .file-row-name {
    font-size: 0.9375rem;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    word-break: break-word;
  }
  
  .file-row-meta {
    font-size: 0.8125rem;
    flex-direction: row;
    align-items: center;
    gap: 0.5rem;
  }
  
  .file-row-meta .separator {
    display: inline;
  }
  
  .row-action-btn {
    width: 40px;
    height: 40px;
    font-size: 1.1rem;
  }
  
  /* 移动端紧凑视图优化 */
  .file-compact-row {
    padding: 0.625rem 0.75rem;
  }
  
  .compact-icon {
    font-size: 1.25rem;
  }
  
  .compact-name {
    font-size: 0.875rem;
  }
  
  .compact-size {
    font-size: 0.75rem;
  }
  
  .file-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .file-card {
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    display: flex;
    flex-direction: row;
    align-items: stretch;
    overflow: hidden;
  }
  
  .file-thumbnail {
    width: 100px;
    min-width: 100px;
    height: 100px;
    aspect-ratio: 1;
    flex-shrink: 0;
  }
  
  .thumbnail-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  
  .file-icon {
    font-size: 2.5rem;
  }
  
  .file-icon-bg {
    width: 50px;
    height: 50px;
  }
  
  .file-details {
    padding: 12px;
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  
  .file-name {
    font-size: 0.9375rem;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    word-break: break-word;
    margin-bottom: 6px;
  }
  
  .file-meta {
    font-size: 0.75rem;
    flex-direction: row;
    align-items: center;
    gap: 0.5rem;
    flex-wrap: wrap;
  }
  
  .separator {
    display: inline;
  }
  
  .file-actions {
    padding: 8px;
    gap: 4px;
    flex-direction: column;
    justify-content: center;
    border-left: 1px solid var(--gray-200);
  }
  
  .action-btn {
    padding: 8px;
    min-width: 36px;
    height: 36px;
  }
  
  .action-icon {
    font-size: 1rem;
  }
  
  .quick-action {
    padding: 0.625rem 1.25rem;
    font-size: 0.8125rem;
  }
}

@media (max-width: 480px) {
  .file-grid {
    grid-template-columns: 1fr;
  }
  
  .file-card {
    display: flex;
    flex-direction: row;
    align-items: center;
  }
  
  .file-thumbnail {
    width: 100px;
    aspect-ratio: 1;
    flex-shrink: 0;
  }
  
  .file-details {
    flex: 1;
    border-bottom: none;
    border-right: 1px solid var(--gray-100);
  }
  
  .file-actions {
    flex-direction: column;
    padding: 0.5rem;
    background: transparent;
  }
  
  .action-btn {
    padding: 0.5rem;
  }
}
</style>
