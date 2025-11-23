<template>
  <Teleport to="body">
    <Transition name="dialog-fade">
      <div v-if="show" class="share-dialog-overlay" @click="close">
        <div class="share-dialog" @click.stop>
          <div class="dialog-header">
            <h3>🔗 分享文件</h3>
            <button @click="close" class="btn-close">×</button>
          </div>
          
          <div class="dialog-body">
            <div class="success-message">
              <span class="icon">✅</span>
              <p>链接已复制到剪贴板</p>
            </div>
            
            <div class="link-container">
              <input 
                ref="linkInput"
                :value="shareLink" 
                readonly 
                class="link-input"
                @click="selectAll"
              />
              <button @click="copyLink" class="btn-copy">
                {{ copied ? '已复制' : '复制' }}
              </button>
            </div>
            
            <div class="share-info">
              <p>📱 分享此链接，让他人访问文件</p>
              <p class="hint">💡 链接永久有效，请妥善保管</p>
            </div>
          </div>
          
          <div class="dialog-footer">
            <button @click="close" class="btn-confirm">确定</button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  shareLink: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:show'])

const linkInput = ref(null)
const copied = ref(false)

watch(() => props.show, (newVal) => {
  if (newVal) {
    copied.value = false
  }
})

function close() {
  emit('update:show', false)
}

function selectAll() {
  linkInput.value?.select()
}

async function copyLink() {
  try {
    await navigator.clipboard.writeText(props.shareLink)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    console.error('Copy failed:', err)
  }
}
</script>

<style scoped>
.share-dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
}

.share-dialog {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 500px;
  width: 100%;
  overflow: hidden;
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.dialog-header {
  padding: 20px 24px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.dialog-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}

.btn-close {
  background: transparent;
  border: none;
  font-size: 2rem;
  line-height: 1;
  cursor: pointer;
  color: white;
  opacity: 0.8;
  transition: opacity 0.2s;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  opacity: 1;
}

.dialog-body {
  padding: 24px;
}

.success-message {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background: #d1fae5;
  border-radius: 12px;
  margin-bottom: 20px;
}

.success-message .icon {
  font-size: 1.5rem;
}

.success-message p {
  margin: 0;
  color: #065f46;
  font-weight: 500;
  font-size: 1rem;
}

.link-container {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
}

.link-input {
  flex: 1;
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  font-family: monospace;
  background-color: #f9fafb;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.link-input:hover {
  border-color: #d1d5db;
  background-color: #f3f4f6;
}

.link-input:focus {
  outline: none;
  border-color: #667eea;
  background-color: white;
}

.btn-copy {
  padding: 12px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-copy:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-copy:active {
  transform: translateY(0);
}

.share-info {
  padding: 16px;
  background: #f0f9ff;
  border-radius: 10px;
  border-left: 4px solid #3b82f6;
}

.share-info p {
  margin: 8px 0;
  color: #1e40af;
  font-size: 0.9rem;
}

.share-info p.hint {
  color: #6b7280;
  font-size: 0.85rem;
}

.dialog-footer {
  padding: 16px 24px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
  background-color: #f9fafb;
}

.btn-confirm {
  padding: 10px 32px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 1rem;
}

.btn-confirm:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-confirm:active {
  transform: translateY(0);
}

/* 过渡动画 */
.dialog-fade-enter-active,
.dialog-fade-leave-active {
  transition: opacity 0.3s ease;
}

.dialog-fade-enter-from,
.dialog-fade-leave-to {
  opacity: 0;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .share-dialog-overlay {
    padding: 0;
    align-items: flex-end;
  }
  
  .share-dialog {
    max-width: 100%;
    border-radius: 16px 16px 0 0;
    animation: slideUpMobile 0.3s ease-out;
  }
  
  @keyframes slideUpMobile {
    from {
      transform: translateY(100%);
    }
    to {
      transform: translateY(0);
    }
  }
  
  .dialog-header {
    padding: 16px 20px;
  }
  
  .dialog-header h3 {
    font-size: 1.1rem;
  }
  
  .dialog-body {
    padding: 20px;
  }
  
  .link-container {
    flex-direction: column;
  }
  
  .btn-copy {
    width: 100%;
    padding: 12px;
  }
  
  .link-input {
    font-size: 13px;
    padding: 10px 12px;
  }
  
  .success-message {
    padding: 12px;
  }
  
  .share-info {
    padding: 12px;
  }
  
  .share-info p {
    font-size: 0.85rem;
  }
}
</style>
