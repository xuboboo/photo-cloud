<template>
  <Teleport to="body">
    <Transition name="preview-fade">
      <div v-if="show" class="image-preview-overlay" @click="close">
        <div class="preview-container" @click.stop>
          <!-- 顶部工具栏 -->
          <div class="preview-header">
            <button @click="close" class="btn-close">✕</button>
            <h3 class="preview-title">{{ fileName }}</h3>
            <button @click="handleDownload" class="btn-download">
              <span v-if="!downloading">⬇️</span>
              <span v-else>⏳</span>
            </button>
          </div>
          
          <!-- 图片展示 -->
          <div class="preview-body">
            <img 
              :src="imageUrl" 
              :alt="fileName"
              class="preview-image"
              @contextmenu="handleContextMenu"
            />
          </div>
          
          <!-- 底部提示 -->
          <div class="preview-footer">
            <p class="hint">💡 长按图片保存到手机</p>
            <p class="file-info">{{ fileSize }} · {{ fileDate }}</p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref } from 'vue'
import { downloadFile } from '../utils/download'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  imageUrl: {
    type: String,
    default: ''
  },
  fileName: {
    type: String,
    default: '图片'
  },
  fileSize: {
    type: String,
    default: ''
  },
  fileDate: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:show', 'download'])

const downloading = ref(false)

function close() {
  emit('update:show', false)
}

async function handleDownload() {
  try {
    downloading.value = true
    await downloadFile(props.imageUrl, props.fileName)
    emit('download')
  } catch (err) {
    console.error('Download failed:', err)
    alert('下载失败：' + err.message)
  } finally {
    downloading.value = false
  }
}

function handleContextMenu(e) {
  // 允许默认的长按保存行为
  // 在移动端，长按会触发contextmenu事件
}
</script>

<style scoped>
.image-preview-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.95);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
}

.preview-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
}

.preview-header {
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(to bottom, rgba(0,0,0,0.8), transparent);
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  z-index: 10;
}

.preview-title {
  flex: 1;
  margin: 0 1rem;
  color: white;
  font-size: 1rem;
  font-weight: 600;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.btn-close,
.btn-download {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  color: white;
  font-size: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.btn-close:active,
.btn-download:active {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(0.95);
}

.preview-body {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4rem 1rem;
  overflow: hidden;
}

.preview-image {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  user-select: none;
  -webkit-user-select: none;
  -webkit-touch-callout: default; /* 允许长按保存 */
}

.preview-footer {
  padding: 1rem;
  background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  text-align: center;
  z-index: 10;
}

.hint {
  margin: 0 0 0.5rem 0;
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.875rem;
}

.file-info {
  margin: 0;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.75rem;
}

/* 过渡动画 */
.preview-fade-enter-active,
.preview-fade-leave-active {
  transition: opacity 0.3s ease;
}

.preview-fade-enter-from,
.preview-fade-leave-to {
  opacity: 0;
}

/* 桌面端优化 */
@media (min-width: 769px) {
  .preview-container {
    max-width: 90vw;
    max-height: 90vh;
    margin: auto;
    border-radius: 12px;
    overflow: hidden;
  }
  
  .preview-header,
  .preview-footer {
    position: relative;
    background: rgba(0, 0, 0, 0.8);
  }
  
  .preview-body {
    padding: 2rem;
    background: rgba(0, 0, 0, 0.9);
  }
  
  .btn-close:hover,
  .btn-download:hover {
    background: rgba(255, 255, 255, 0.2);
  }
}

/* 移动端横屏 */
@media (max-width: 768px) and (orientation: landscape) {
  .preview-body {
    padding: 3rem 1rem;
  }
}
</style>
