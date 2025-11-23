<template>
  <transition name="dialog-fade">
    <div v-if="show" class="dialog-overlay" @click="handleOverlayClick">
      <div class="dialog-container" @click.stop>
        <!-- 标题 -->
        <div class="dialog-header">
          <h3>{{ title }}</h3>
          <button @click="handleCancel" class="btn-close">✕</button>
        </div>

        <!-- 内容 -->
        <div class="dialog-body">
          <p v-if="message" class="dialog-message">{{ message }}</p>
          
          <!-- 输入框（单个） -->
          <div v-if="type === 'prompt'" class="input-wrapper">
            <input 
              ref="inputRef"
              v-model="inputValue" 
              :type="inputType"
              :placeholder="placeholder"
              class="dialog-input"
              @keyup.enter="handleConfirm"
            />
          </div>

          <!-- 文本域（批量） -->
          <div v-if="type === 'textarea'" class="input-wrapper">
            <textarea 
              ref="textareaRef"
              v-model="inputValue" 
              :placeholder="placeholder"
              class="dialog-textarea"
              rows="6"
            ></textarea>
            <div class="input-hint">{{ hint }}</div>
          </div>
        </div>

        <!-- 底部按钮 -->
        <div class="dialog-footer">
          <button @click="handleCancel" class="btn-cancel">
            {{ cancelText }}
          </button>
          <button @click="handleConfirm" class="btn-confirm">
            {{ confirmText }}
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    default: 'confirm' // 'confirm', 'prompt', 'textarea'
  },
  title: {
    type: String,
    default: '提示'
  },
  message: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: '请输入'
  },
  hint: {
    type: String,
    default: ''
  },
  defaultValue: {
    type: String,
    default: ''
  },
  inputType: {
    type: String,
    default: 'text'
  },
  confirmText: {
    type: String,
    default: '确定'
  },
  cancelText: {
    type: String,
    default: '取消'
  }
})

const emit = defineEmits(['update:show', 'confirm', 'cancel'])

const inputValue = ref('')
const inputRef = ref(null)
const textareaRef = ref(null)

// 监听显示状态，自动聚焦
watch(() => props.show, async (newVal) => {
  if (newVal) {
    inputValue.value = props.defaultValue
    await nextTick()
    if (props.type === 'prompt' && inputRef.value) {
      inputRef.value.focus()
    } else if (props.type === 'textarea' && textareaRef.value) {
      textareaRef.value.focus()
    }
  }
})

function handleOverlayClick() {
  handleCancel()
}

function handleCancel() {
  emit('update:show', false)
  emit('cancel')
  inputValue.value = ''
}

function handleConfirm() {
  if (props.type !== 'confirm' && !inputValue.value.trim()) {
    return
  }
  
  emit('update:show', false)
  emit('confirm', inputValue.value)
  inputValue.value = ''
}
</script>

<style scoped>
/* 遮罩层 */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
}

/* 弹窗容器 */
.dialog-container {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  display: flex;
  flex-direction: column;
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 标题栏 */
.dialog-header {
  padding: 20px 20px 16px;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dialog-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #2d3748;
}

.btn-close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: #f7fafc;
  color: #718096;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  background: #edf2f7;
  color: #2d3748;
}

/* 内容区 */
.dialog-body {
  padding: 20px;
  flex: 1;
  overflow-y: auto;
}

.dialog-message {
  margin: 0 0 16px 0;
  color: #4a5568;
  font-size: 15px;
  line-height: 1.6;
  white-space: pre-wrap;
}

.input-wrapper {
  margin-top: 8px;
}

.dialog-input {
  width: 100%;
  padding: 14px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 16px;
  transition: all 0.2s;
  box-sizing: border-box;
}

.dialog-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.dialog-textarea {
  width: 100%;
  padding: 14px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 15px;
  font-family: inherit;
  resize: vertical;
  transition: all 0.2s;
  box-sizing: border-box;
  min-height: 120px;
}

.dialog-textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.input-hint {
  margin-top: 8px;
  font-size: 13px;
  color: #a0aec0;
}

/* 底部按钮 */
.dialog-footer {
  padding: 16px 20px 20px;
  display: flex;
  gap: 12px;
  border-top: 1px solid #e2e8f0;
}

.btn-cancel,
.btn-confirm {
  flex: 1;
  padding: 14px;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-cancel {
  background: #f7fafc;
  color: #718096;
}

.btn-cancel:hover {
  background: #edf2f7;
}

.btn-cancel:active {
  transform: scale(0.98);
}

.btn-confirm {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-confirm:hover {
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
  transform: translateY(-1px);
}

.btn-confirm:active {
  transform: translateY(0);
}

/* 动画效果 */
.dialog-fade-enter-active,
.dialog-fade-leave-active {
  transition: opacity 0.3s ease;
}

.dialog-fade-enter-active .dialog-container,
.dialog-fade-leave-active .dialog-container {
  transition: transform 0.3s ease;
}

.dialog-fade-enter-from,
.dialog-fade-leave-to {
  opacity: 0;
}

.dialog-fade-enter-from .dialog-container {
  transform: translateY(30px);
}

.dialog-fade-leave-to .dialog-container {
  transform: translateY(30px);
}

/* 移动端优化 */
@media (max-width: 480px) {
  .dialog-overlay {
    padding: 0;
    align-items: flex-end;
  }
  
  .dialog-container {
    max-width: 100%;
    max-height: 90vh;
    border-radius: 20px 20px 0 0;
  }
  
  .dialog-header h3 {
    font-size: 17px;
  }
  
  .dialog-input,
  .dialog-textarea {
    font-size: 16px; /* 防止iOS缩放 */
  }
  
  .btn-cancel,
  .btn-confirm {
    padding: 13px;
    font-size: 15px;
  }
}
</style>
