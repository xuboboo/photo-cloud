<template>
  <div class="home-page">
    <!-- 顶部导航栏 -->
    <nav class="navbar">
      <div class="nav-container">
        <div class="nav-brand">
          <h1>📷 Photo Cloud</h1>
        </div>
        <div class="nav-menu">
          <a href="#features">功能特点</a>
          <a href="#contact">联系我们</a>
          <button @click="goToLogin" class="btn-primary">免费使用</button>
        </div>
      </div>
    </nav>

    <!-- 英雄区 -->
    <section class="hero-section">
      <div class="hero-content">
        <h1 class="hero-title">专业的云相册管理系统</h1>
        <p class="hero-subtitle">安全可靠的云存储服务，让您的照片和文件随时随地可访问</p>
        <div class="hero-features">
          <span>✅ 免费1GB存储</span>
          <span>✅ 企业级安全</span>
          <span>✅ 多端同步</span>
        </div>
        <div class="hero-actions">
          <button @click="goToLogin" class="btn-hero">立即开始使用</button>
          <button @click="scrollToFeatures" class="btn-secondary">了解更多</button>
        </div>
      </div>
      <div class="hero-image">
        <div class="floating-card">
          <div class="card-icon">📁</div>
          <p>1000+ 张照片</p>
        </div>
        <div class="floating-card delay-1">
          <div class="card-icon">🔒</div>
          <p>安全加密</p>
        </div>
        <div class="floating-card delay-2">
          <div class="card-icon">☁️</div>
          <p>云端同步</p>
        </div>
      </div>
    </section>

    <!-- 功能特点 -->
    <section id="features" class="features-section">
      <div class="section-container">
        <h2 class="section-title">为什么选择 Photo Cloud？</h2>
        <p class="section-subtitle">强大的功能，简单的操作，专业的服务</p>
        
        <div class="features-grid">
          <div class="feature-card">
            <div class="feature-icon">📤</div>
            <h3>快速上传</h3>
            <p>支持批量上传、拖拽上传，多种上传方式满足不同需求</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">👁️</div>
            <h3>在线预览</h3>
            <p>高清图片预览，支持多种格式，随时随地查看您的文件</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">🔗</div>
            <h3>便捷分享</h3>
            <p>一键生成分享链接，支持密码保护和有效期设置</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">🔐</div>
            <h3>安全可靠</h3>
            <p>企业级数据加密，多重备份机制，保障数据安全</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">📱</div>
            <h3>多端同步</h3>
            <p>支持桌面端和移动端，数据实时同步，随时访问</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">⚡</div>
            <h3>极速访问</h3>
            <p>全球CDN加速，毫秒级响应，极致的使用体验</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA区域 -->
    <section class="cta-section">
      <div class="cta-content">
        <h2>准备开始了吗？</h2>
        <p>注册账户，立即享受1GB免费存储空间</p>
        <button @click="goToLogin" class="btn-cta">免费注册</button>
      </div>
    </section>

    <!-- 页脚 -->
    <Footer @show-privacy="showPrivacyDialog" @show-terms="showTermsDialog" />

    <!-- 隐私政策弹窗 -->
    <PrivacyPolicy v-model:show="privacyDialogShow" type="privacy" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Footer from '../components/Footer.vue'
import PrivacyPolicy from '../components/PrivacyPolicy.vue'

const router = useRouter()
const privacyDialogShow = ref(false)

const goToLogin = () => {
  router.push('/login?mode=register')
}

const scrollToFeatures = () => {
  document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })
}

const contactUs = () => {
  window.location.href = 'mailto:news@tournews.top'
}

const showPrivacyDialog = () => {
  privacyDialogShow.value = true
}

const showTermsDialog = () => {
  privacyDialogShow.value = true
}
</script>

<style scoped>
/* 全局移动端优化 */
* {
  -webkit-tap-highlight-color: transparent;
  -webkit-touch-callout: none;
}

.home-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  overflow-x: hidden;
}

/* 平滑滚动 */
html {
  scroll-behavior: smooth;
}

/* 导航栏 */
.navbar {
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 100;
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-brand h1 {
  font-size: 1.5rem;
  margin: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.nav-menu {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.nav-menu a {
  text-decoration: none;
  color: #333;
  font-weight: 500;
  transition: color 0.3s;
}

.nav-menu a:hover {
  color: #667eea;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  user-select: none;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(102, 126, 234, 0.3);
}

.btn-primary:active {
  transform: translateY(0);
  box-shadow: 0 4px 8px rgba(102, 126, 234, 0.2);
}

/* 英雄区 */
.hero-section {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 2rem 3rem;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
  align-items: center;
  min-height: calc(100vh - 80px);
}

.hero-title {
  font-size: 3rem;
  font-weight: 800;
  margin: 0 0 1rem 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1.2;
}

.hero-subtitle {
  font-size: 1.25rem;
  color: #666;
  margin: 0 0 2rem 0;
  line-height: 1.6;
}

.hero-features {
  display: flex;
  gap: 1.5rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.hero-features span {
  background: #f0f4ff;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: 500;
  color: #667eea;
}

.hero-actions {
  display: flex;
  gap: 1rem;
}

.btn-hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1rem 2rem;
  border: none;
  border-radius: 10px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  user-select: none;
}

.btn-hero:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 24px rgba(102, 126, 234, 0.4);
}

.btn-hero:active {
  transform: translateY(-1px);
  box-shadow: 0 6px 12px rgba(102, 126, 234, 0.3);
}

.btn-secondary {
  background: white;
  color: #667eea;
  padding: 1rem 2rem;
  border: 2px solid #667eea;
  border-radius: 10px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
}

.btn-secondary:hover {
  background: #667eea;
  color: white;
}

.btn-secondary:active {
  transform: scale(0.98);
}

/* 浮动卡片 */
.hero-image {
  position: relative;
  height: 400px;
}

.floating-card {
  position: absolute;
  background: white;
  padding: 1.5rem;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  animation: float 3s ease-in-out infinite;
}

.floating-card:nth-child(1) {
  top: 20%;
  left: 10%;
}

.floating-card:nth-child(2) {
  top: 50%;
  right: 10%;
  animation-delay: 1s;
}

.floating-card:nth-child(3) {
  bottom: 10%;
  left: 30%;
  animation-delay: 2s;
}

.card-icon {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.floating-card p {
  margin: 0;
  font-weight: 600;
  color: #333;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-20px);
  }
}

/* 功能特点 */
.features-section {
  background: #f8fafc;
  padding: 3rem 2rem;
}

.section-container {
  max-width: 1200px;
  margin: 0 auto;
}

.section-title {
  font-size: 2.5rem;
  font-weight: 800;
  text-align: center;
  margin: 0 0 1rem 0;
  color: #1a202c;
}

.section-subtitle {
  font-size: 1.1rem;
  text-align: center;
  color: #666;
  margin: 0 0 3rem 0;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
}

.feature-card {
  background: white;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
  transition: transform 0.3s, box-shadow 0.3s;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.1);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0 0 0.5rem 0;
  color: #1a202c;
}

.feature-card p {
  margin: 0;
  color: #666;
  line-height: 1.6;
}

/* CTA区域 */
.cta-section {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 3rem 2rem;
  text-align: center;
}

.cta-content h2 {
  font-size: 2.5rem;
  font-weight: 800;
  color: white;
  margin: 0 0 1rem 0;
}

.cta-content p {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.9);
  margin: 0 0 2rem 0;
}

.btn-cta {
  background: white;
  color: #667eea;
  padding: 1.25rem 3rem;
  border: none;
  border-radius: 12px;
  font-size: 1.25rem;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  user-select: none;
}

.btn-cta:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.2);
}

.btn-cta:active {
  transform: translateY(-1px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}

/* 响应式 */
@media (max-width: 992px) {
  .hero-section {
    grid-template-columns: 1fr;
    text-align: center;
    padding: 2rem 1.5rem;
    min-height: auto;
  }
  
  .hero-image {
    display: none;
  }
  
  .features-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .features-section {
    padding: 2rem 1.5rem;
  }
  
  .cta-section {
    padding: 2.5rem 1.5rem;
  }
  
  .nav-menu {
    gap: 1rem;
  }
  
  .nav-menu a {
    display: none;
  }
}

@media (max-width: 768px) {
  .features-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
  
  .hero-title {
    font-size: 1.75rem;
    line-height: 1.3;
  }
  
  .hero-subtitle {
    font-size: 0.95rem;
    line-height: 1.5;
  }
  
  .hero-section {
    padding: 1.5rem 1rem;
  }
  
  .hero-features {
    flex-direction: column;
    gap: 0.75rem;
    align-items: center;
  }
  
  .hero-features span {
    font-size: 0.85rem;
    padding: 0.4rem 1rem;
  }
  
  .hero-actions {
    flex-direction: column;
    width: 100%;
    gap: 0.75rem;
  }
  
  .btn-hero,
  .btn-secondary {
    width: 100%;
    padding: 0.875rem 1.5rem;
    font-size: 1rem;
  }
  
  .features-section {
    padding: 2rem 1rem;
  }
  
  .section-title {
    font-size: 1.75rem;
  }
  
  .section-subtitle {
    font-size: 0.95rem;
  }
  
  .feature-card {
    padding: 1.5rem;
  }
  
  .feature-icon {
    font-size: 2.5rem;
  }
  
  .feature-card h3 {
    font-size: 1.1rem;
  }
  
  .feature-card p {
    font-size: 0.9rem;
  }
  
  .cta-section {
    padding: 2rem 1rem;
  }
  
  .cta-content h2 {
    font-size: 1.75rem;
  }
  
  .cta-content p {
    font-size: 1rem;
  }
  
  .btn-cta {
    width: 100%;
    max-width: 300px;
    padding: 1rem 2rem;
    font-size: 1.1rem;
  }
  
  .navbar {
    padding: 0.75rem 0;
  }
  
  .nav-container {
    padding: 0 1rem;
  }
  
  .nav-brand h1 {
    font-size: 1.25rem;
  }
  
  .btn-primary {
    padding: 0.625rem 1.25rem;
    font-size: 0.9rem;
  }
}
</style>
