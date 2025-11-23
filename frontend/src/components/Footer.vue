<template>
  <footer v-if="!isMobile" class="desktop-footer">
    <div class="footer-container">
      <div class="footer-brand">
        <h3>Photo Cloud</h3>
        <p>专业的云相册管理系统</p>
        <p class="copyright">© 2025 Photo Cloud Technology Studio. All Rights Reserved.</p>
      </div>
      <div class="footer-links">
        <div class="link-column">
          <h4>产品</h4>
          <router-link to="/">首页</router-link>
          <router-link to="/dashboard">工作台</router-link>
          <router-link to="/upload">上传文件</router-link>
          <router-link to="/blog">博客</router-link>
        </div>
        <div class="link-column">
          <h4>支持</h4>
          <a href="mailto:news@tournews.top">联系我们</a>
        </div>
        <div class="link-column">
          <h4>关于</h4>
          <a href="https://www.tournews.top" target="_blank">官方网站</a>
        </div>
      </div>
      <div class="footer-contact">
        <h4>联系方式</h4>
        <p>news@tournews.top</p>
        <p>www.tournews.top</p>
      </div>
    </div>
    <div class="footer-bottom">
      <p>本网站使用Cookies以提供更好的用户体验</p>
    </div>
  </footer>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
const isMobile = ref(false)
const checkMobile = () => { isMobile.value = window.innerWidth <= 768 }
onMounted(() => { checkMobile(); window.addEventListener('resize', checkMobile) })
onUnmounted(() => { window.removeEventListener('resize', checkMobile) })
</script>

<style scoped>
.desktop-footer { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 3rem 2rem 1rem; margin-top: auto; }
.footer-container { max-width: 1200px; margin: 0 auto; display: grid; grid-template-columns: 2fr 3fr 2fr; gap: 3rem; padding-bottom: 2rem; border-bottom: 1px solid rgba(255,255,255,0.2); }
.footer-brand h3 { font-size: 1.5rem; margin: 0 0 0.5rem 0; font-weight: 700; }
.footer-brand p { margin: 0.25rem 0; opacity: 0.9; font-size: 0.9rem; }
.copyright { margin-top: 1rem !important; font-size: 0.85rem !important; opacity: 0.7 !important; }
.footer-links { display: flex; gap: 3rem; justify-content: center; }
.link-column h4 { font-size: 1rem; margin: 0 0 1rem 0; font-weight: 600; }
.link-column a { display: block; color: white; text-decoration: none; margin: 0.5rem 0; opacity: 0.8; transition: all 0.3s ease; font-size: 0.9rem; }
.link-column a:hover { opacity: 1; transform: translateX(5px); }
.footer-contact h4 { font-size: 1rem; margin: 0 0 1rem 0; font-weight: 600; }
.footer-contact p { margin: 0.5rem 0; font-size: 0.9rem; opacity: 0.9; }
.footer-bottom { max-width: 1200px; margin: 0 auto; padding-top: 1.5rem; text-align: center; }
.footer-bottom p { margin: 0; font-size: 0.85rem; opacity: 0.7; }
@media (max-width: 992px) { .footer-container { grid-template-columns: 1fr 1fr; gap: 2rem; } .footer-contact { grid-column: 1 / -1; } }
@media (max-width: 768px) { .desktop-footer { display: none; } }
</style>
