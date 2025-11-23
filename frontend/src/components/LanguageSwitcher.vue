<template>
  <div class="language-switcher">
    <button @click="toggleDropdown" class="language-btn" :aria-label="$t('settings.language')">
      <span class="flag">{{ currentLanguage.flag }}</span>
      <span class="name">{{ currentLanguage.name }}</span>
      <svg class="arrow" :class="{ open: isOpen }" width="12" height="12" viewBox="0 0 12 12" fill="none">
        <path d="M3 4.5L6 7.5L9 4.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </button>
    
    <transition name="dropdown">
      <div v-if="isOpen" class="dropdown" ref="dropdown">
        <button
          v-for="locale in languages"
          :key="locale.code"
          @click="changeLanguage(locale.code)"
          class="dropdown-item"
          :class="{ active: locale.code === currentLocale }"
        >
          <span class="flag">{{ locale.flag }}</span>
          <span class="name">{{ locale.name }}</span>
          <svg v-if="locale.code === currentLocale" class="check" width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M13.3333 4L6 11.3333L2.66666 8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { SUPPORT_LOCALES, saveLocale } from '../i18n'

const { locale } = useI18n()
const isOpen = ref(false)
const dropdown = ref(null)

const languages = SUPPORT_LOCALES

const currentLocale = computed(() => locale.value)
const currentLanguage = computed(() => {
  return languages.find(l => l.code === currentLocale.value) || languages[1]
})

const toggleDropdown = () => {
  isOpen.value = !isOpen.value
}

const changeLanguage = (code) => {
  locale.value = code
  saveLocale(code)
  isOpen.value = false
  
  // 更新 HTML lang 属性
  document.documentElement.lang = code
  
  // 更新页面 SEO meta
  updatePageMeta()
}

const updatePageMeta = () => {
  // 这个函数将在路由变化时调用 SEO 更新
  // 具体实现在 router afterEach 钩子中
}

// 点击外部关闭下拉框
const handleClickOutside = (event) => {
  if (dropdown.value && !dropdown.value.contains(event.target) && 
      !event.target.closest('.language-btn')) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  // 设置初始语言
  document.documentElement.lang = currentLocale.value
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.language-switcher {
  position: relative;
}

.language-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius);
  background: white;
  cursor: pointer;
  font-size: 14px;
  transition: var(--transition);
  color: var(--gray-700);
}

.language-btn:hover {
  border-color: var(--gray-300);
  background: var(--gray-50);
}

.flag {
  font-size: 18px;
  line-height: 1;
}

.name {
  font-weight: 500;
}

.arrow {
  transition: transform 0.2s;
  color: var(--gray-400);
}

.arrow.open {
  transform: rotate(180deg);
}

.dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  min-width: 200px;
  background: white;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  padding: 8px;
  z-index: 1000;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 10px 12px;
  border: none;
  border-radius: var(--radius);
  background: transparent;
  cursor: pointer;
  font-size: 14px;
  transition: var(--transition);
  color: var(--gray-700);
  text-align: left;
}

.dropdown-item:hover {
  background: var(--gray-50);
}

.dropdown-item.active {
  background: var(--primary-50);
  color: var(--primary-700);
  font-weight: 600;
}

.check {
  margin-left: auto;
  color: var(--primary-600);
}

/* 过渡动画 */
.dropdown-enter-active,
.dropdown-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* 移动端适配 */
@media (max-width: 768px) {
  .language-btn .name {
    display: none;
  }
  
  .dropdown {
    right: auto;
    left: 50%;
    transform: translateX(-50%);
  }
}
</style>
