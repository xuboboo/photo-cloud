<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useUserStore } from './stores/user'

const userStore = useUserStore()

// 异步初始化，不阻塞页面渲染
onMounted(() => {
  userStore.initialize()
  
  // 确保页面加载时滚动到顶部（修复移动端问题）
  window.scrollTo(0, 0)
})

</script>

<style scoped>
#app {
  width: 100%;
  min-height: 100vh;
}
</style>
