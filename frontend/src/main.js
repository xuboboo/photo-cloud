import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

// 禁止移动端双指缩放和双击缩放
document.addEventListener('gesturestart', function (e) {
  e.preventDefault()
})

document.addEventListener('gesturechange', function (e) {
  e.preventDefault()
})

document.addEventListener('gestureend', function (e) {
  e.preventDefault()
})

// 禁止双击缩放
let lastTouchEnd = 0
document.addEventListener('touchend', function (event) {
  const now = Date.now()
  if (now - lastTouchEnd <= 300) {
    event.preventDefault()
  }
  lastTouchEnd = now
}, false)

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

app.mount('#app')
