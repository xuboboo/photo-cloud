import { createI18n } from 'vue-i18n'
import zh from './locales/zh-CN'
import en from './locales/en-US'
import ja from './locales/ja-JP'
import ko from './locales/ko-KR'
import es from './locales/es-ES'
import fr from './locales/fr-FR'
import de from './locales/de-DE'

// 支持的语言列表
export const SUPPORT_LOCALES = [
  { code: 'zh-CN', name: '简体中文', flag: '🇨🇳' },
  { code: 'en-US', name: 'English', flag: '🇺🇸' },
  { code: 'ja-JP', name: '日本語', flag: '🇯🇵' },
  { code: 'ko-KR', name: '한국어', flag: '🇰🇷' },
  { code: 'es-ES', name: 'Español', flag: '🇪🇸' },
  { code: 'fr-FR', name: 'Français', flag: '🇫🇷' },
  { code: 'de-DE', name: 'Deutsch', flag: '🇩🇪' }
]

// 检测浏览器语言
function getBrowserLocale() {
  const navigatorLocale = navigator.language || navigator.userLanguage
  
  // 精确匹配
  if (SUPPORT_LOCALES.some(l => l.code === navigatorLocale)) {
    return navigatorLocale
  }
  
  // 模糊匹配（只匹配语言代码）
  const languageCode = navigatorLocale.split('-')[0]
  const matched = SUPPORT_LOCALES.find(l => l.code.startsWith(languageCode))
  
  return matched ? matched.code : 'en-US'
}

// 从 localStorage 获取保存的语言设置
function getSavedLocale() {
  return localStorage.getItem('user-locale')
}

// 保存语言设置到 localStorage
export function saveLocale(locale) {
  localStorage.setItem('user-locale', locale)
}

// 确定初始语言
const initialLocale = getSavedLocale() || getBrowserLocale()

const i18n = createI18n({
  legacy: false, // 使用 Composition API 模式
  locale: initialLocale,
  fallbackLocale: 'en-US',
  messages: {
    'zh-CN': zh,
    'en-US': en,
    'ja-JP': ja,
    'ko-KR': ko,
    'es-ES': es,
    'fr-FR': fr,
    'de-DE': de
  },
  globalInjection: true,
  silentTranslationWarn: true,
  silentFallbackWarn: true
})

export default i18n
