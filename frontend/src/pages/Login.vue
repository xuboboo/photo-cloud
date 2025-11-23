<template>
  <div class="login-page">
    <!-- 背景装饰 -->
    <div class="bg-decoration">
      <div class="circle circle-1"></div>
      <div class="circle circle-2"></div>
      <div class="circle circle-3"></div>
    </div>

    <div class="login-container">
      <!-- Logo区域 -->
      <div class="logo-section">
        <div class="logo-icon">📸</div>
        <h1 class="app-title">Photo Cloud</h1>
        <p class="app-subtitle">安全 · 快速 · 简单</p>
      </div>

      <!-- Tab切换 -->
      <div class="auth-tabs">
        <button 
          @click="isLogin = true" 
          :class="['tab-btn', { active: isLogin }]"
        >
          登录
        </button>
        <button 
          @click="isLogin = false" 
          :class="['tab-btn', { active: !isLogin }]"
        >
          注册
        </button>
      </div>

      <!-- 表单 -->
      <form @submit.prevent="handleSubmit" class="auth-form">
        <div class="input-group">
          <div class="input-icon">📧</div>
          <input 
            v-model="email" 
            type="email" 
            placeholder="邮箱地址" 
            required 
            autocomplete="email"
          />
        </div>

        <div class="input-group">
          <div class="input-icon">🔒</div>
          <input 
            v-model="password" 
            :type="showPassword ? 'text' : 'password'" 
            placeholder="密码（至少6位）" 
            required 
            minlength="6"
            autocomplete="current-password"
          />
          <button 
            type="button" 
            @click="showPassword = !showPassword" 
            class="toggle-password"
          >
            {{ showPassword ? '👁️' : '👁️‍🗨️' }}
          </button>
        </div>

        <!-- 协议同意（仅注册时显示） -->
        <div v-if="!isLogin" class="agreement-box">
          <label class="agreement-label">
            <input 
              type="checkbox" 
              v-model="agreedToTerms" 
              class="agreement-checkbox"
            />
            <span class="agreement-text">
              我已阅读并同意
              <button type="button" @click="showPolicy('privacy')" class="link-btn">《隐私政策》</button>
              和
              <button type="button" @click="showPolicy('terms')" class="link-btn">《服务条款》</button>
            </span>
          </label>
        </div>

        <!-- 错误提示 -->
        <transition name="fade">
          <div v-if="error" class="error-banner">
            <span class="error-icon">⚠️</span>
            <span class="error-text">{{ error }}</span>
          </div>
        </transition>

        <!-- 提交按钮 -->
        <button type="submit" :disabled="loading || (!isLogin && !agreedToTerms)" class="submit-btn">
          <span v-if="!loading">{{ isLogin ? '立即登录' : '创建账户' }}</span>
          <span v-else class="loading-spinner">
            <span class="spinner"></span>
            处理中...
          </span>
        </button>
      </form>

      <!-- 提示信息 -->
      <div class="info-text">
        <template v-if="isLogin">
          <p>还没有账户？<button @click="isLogin = false" class="link-btn">立即注册</button></p>
        </template>
        <template v-else>
          <p>已有账户？<button @click="isLogin = true" class="link-btn">立即登录</button></p>
          <p class="hint">注册后请检查邮箱完成验证</p>
        </template>
      </div>
    </div>

    <!-- 底部版权 -->
    <div class="page-footer">
      <p>© 2025 Photo Cloud Technology Studio. All Rights Reserved.</p>
    </div>

    <!-- 隐私政策弹窗 -->
    <PrivacyPolicy 
      v-model:show="policyDialogShow"
      :type="policyType"
    />
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login, register } from '../api/auth'
import { checkEmailBeforeSignup } from '../api/admin'
import { useUserStore } from '../stores/user'
import PrivacyPolicy from '../components/PrivacyPolicy.vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const isLogin = ref(true)

// 检查URL参数，如果是从首页跳转过来要注册，则默认显示注册表单
onMounted(() => {
  if (route.query.mode === 'register') {
    isLogin.value = false
  }
})

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const error = ref('')
const agreedToTerms = ref(false)

// 隐私政策弹窗
const policyDialogShow = ref(false)
const policyType = ref('privacy') // 'privacy' or 'terms'

function showPolicy(type) {
  policyType.value = type
  policyDialogShow.value = true
}

// 监听模式切换，清空错误
watch(isLogin, () => {
  error.value = ''
})

async function handleSubmit() {
  try {
    loading.value = true
    error.value = ''

    if (isLogin.value) {
      const result = await login(email.value, password.value)
      const user = result?.user || result?.data?.user
      if (user) {
        userStore.setUser(user)
        router.push('/dashboard')
      } else {
        throw new Error('登录失败，未获取到用户信息')
      }
    } else {
      // 注册前检查邮箱是否在黑名单中
      const blacklistCheck = await checkEmailBeforeSignup(email.value)
      
      if (!blacklistCheck.allowed) {
        error.value = blacklistCheck.message || '该邮箱已被禁止注册，如有疑问请联系管理员'
        loading.value = false
        return
      }
      
      const result = await register(email.value, password.value)
      const user = result?.user || result?.data?.user
      
      if (user) {
        alert('注册成功！请检查邮箱验证链接（如果启用了邮箱验证）')
        isLogin.value = true
        // 清空表单
        email.value = ''
        password.value = ''
      } else {
        // 注册成功但需要邮箱验证
        alert('注册成功！请检查邮箱并点击验证链接后再登录')
        isLogin.value = true
        email.value = ''
        password.value = ''
      }
    }
  } catch (err) {
    console.error('Auth error:', err)
    error.value = err.message || (isLogin.value ? '登录失败' : '注册失败')
  } finally {
    loading.value = false
  }
}

</script>

<style scoped>
/* ===== 页面布局 ===== */
.login-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px 20px 80px 20px; /* 底部留出更多空间 */
  position: relative;
  overflow: hidden;
}

/* ===== 背景装饰 ===== */
.bg-decoration {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  pointer-events: none;
  z-index: 0;
}

.circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  animation: float 20s infinite ease-in-out;
}

.circle-1 {
  width: 300px;
  height: 300px;
  top: -100px;
  right: -100px;
  animation-delay: 0s;
}

.circle-2 {
  width: 200px;
  height: 200px;
  bottom: -50px;
  left: -50px;
  animation-delay: 5s;
}

.circle-3 {
  width: 150px;
  height: 150px;
  top: 50%;
  left: 10%;
  animation-delay: 10s;
}

@keyframes float {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-30px) scale(1.1); }
}

/* ===== 主容器 ===== */
.login-container {
  width: 100%;
  max-width: 400px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 32px 28px;
  position: relative;
  z-index: 1;
  animation: slideUp 0.5s ease-out;
  margin-bottom: 20px; /* 与版权信息保持距离 */
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

/* ===== Logo区域 ===== */
.logo-section {
  text-align: center;
  margin-bottom: 24px;
}

.logo-icon {
  font-size: 56px;
  margin-bottom: 12px;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.app-title {
  margin: 0 0 6px 0;
  font-size: 28px;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.app-subtitle {
  margin: 0;
  font-size: 13px;
  color: #718096;
  font-weight: 500;
}

/* ===== Tab切换 ===== */
.auth-tabs {
  display: flex;
  gap: 6px;
  margin-bottom: 20px;
  background: #f7fafc;
  padding: 4px;
  border-radius: 10px;
}

.tab-btn {
  flex: 1;
  padding: 10px;
  border: none;
  background: transparent;
  color: #718096;
  font-size: 15px;
  font-weight: 600;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

/* ===== 表单 ===== */
.auth-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.input-group {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 16px;
  font-size: 20px;
  pointer-events: none;
  z-index: 1;
}

.input-group input {
  width: 100%;
  padding: 14px 14px 14px 48px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 15px;
  transition: all 0.3s ease;
  background: white;
}

.input-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.toggle-password {
  position: absolute;
  right: 16px;
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  padding: 4px;
  transition: transform 0.2s ease;
}

.toggle-password:hover {
  transform: scale(1.2);
}

/* ===== 协议同意 ===== */
.agreement-box {
  margin: 12px 0;
}

.agreement-label {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  cursor: pointer;
  user-select: none;
}

.agreement-checkbox {
  width: 18px;
  height: 18px;
  margin-top: 2px;
  cursor: pointer;
  accent-color: #667eea;
  flex-shrink: 0;
}

.agreement-text {
  flex: 1;
  font-size: 13px;
  color: #4a5568;
  line-height: 1.5;
}

.agreement-text .link-btn {
  background: none;
  border: none;
  color: #667eea;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 0;
  text-decoration: none;
  transition: all 0.2s;
}

.agreement-text .link-btn:hover {
  color: #764ba2;
  text-decoration: underline;
}

/* ===== 错误提示 ===== */
.error-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: linear-gradient(135deg, #fff5f5 0%, #fed7d7 100%);
  border: 2px solid #fc8181;
  border-radius: 12px;
  animation: shake 0.5s;
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-10px); }
  75% { transform: translateX(10px); }
}

.error-icon {
  font-size: 20px;
}

.error-text {
  flex: 1;
  color: #c53030;
  font-size: 14px;
  font-weight: 500;
}

/* ===== 提交按钮 ===== */
.submit-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 16px rgba(102, 126, 234, 0.4);
  position: relative;
  overflow: hidden;
}

.submit-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
  transition: left 0.5s;
}

.submit-btn:hover:not(:disabled)::before {
  left: 100%;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
}

.submit-btn:active:not(:disabled) {
  transform: translateY(0);
}

.submit-btn:disabled {
  background: #cbd5e0;
  cursor: not-allowed;
  box-shadow: none;
}

.loading-spinner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ===== 提示信息 ===== */
.info-text {
  margin-top: 20px;
  text-align: center;
}

.info-text p {
  margin: 6px 0;
  color: #718096;
  font-size: 13px;
}

.link-btn {
  background: none;
  border: none;
  color: #667eea;
  font-weight: 600;
  cursor: pointer;
  text-decoration: underline;
  padding: 0;
  transition: color 0.2s;
}

.link-btn:hover {
  color: #764ba2;
}

.hint {
  font-size: 12px !important;
  color: #a0aec0 !important;
  margin-top: 12px !important;
}

/* ===== 页面底部 ===== */
.page-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  text-align: center;
  padding: 24px 20px;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.2) 60%, transparent);
  backdrop-filter: blur(10px);
  z-index: 1;
  animation: fadeInUp 1s ease-out 0.5s both;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.page-footer p {
  margin: 0;
  color: white;
  font-size: 15px;
  font-weight: 600;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.6);
  letter-spacing: 1.2px;
  line-height: 1.6;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
  transition: all 0.3s ease;
}

.page-footer p:hover {
  letter-spacing: 1.6px;
  text-shadow: 0 3px 15px rgba(0, 0, 0, 0.8);
  transform: scale(1.02);
}

/* ===== 动画效果 ===== */
.fade-enter-active, .fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}

.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* ===== 移动端适配 ===== */
@media (max-width: 480px) {
  .login-page {
    padding: 15px 15px 70px 15px;
  }
  
  .login-container {
    padding: 28px 22px;
    border-radius: 18px;
    max-width: 360px;
    margin-bottom: 15px;
  }
  
  .logo-section {
    margin-bottom: 20px;
  }
  
  .logo-icon {
    font-size: 48px;
    margin-bottom: 10px;
  }
  
  .app-title {
    font-size: 24px;
  }
  
  .app-subtitle {
    font-size: 12px;
  }
  
  .auth-tabs {
    margin-bottom: 16px;
  }
  
  .tab-btn {
    font-size: 14px;
    padding: 9px;
  }
  
  .auth-form {
    gap: 14px;
  }
  
  .input-group input {
    font-size: 16px; /* 防止iOS自动缩放 */
    padding: 13px 13px 13px 46px;
  }
  
  .submit-btn {
    padding: 13px;
    font-size: 15px;
  }
  
  .info-text {
    margin-top: 16px;
  }
  
  .page-footer {
    padding: 18px 16px;
  }
  
  .page-footer p {
    font-size: 12px;
    letter-spacing: 0.5px;
    font-weight: 600;
  }
}

/* ===== 横屏适配 ===== */
@media (max-height: 600px) and (orientation: landscape) {
  .login-page {
    padding: 10px 20px 60px 20px;
  }
  
  .login-container {
    padding: 20px 28px;
    max-width: 85%;
    margin-bottom: 10px;
  }
  
  .logo-section {
    margin-bottom: 16px;
  }
  
  .logo-icon {
    font-size: 42px;
    margin-bottom: 8px;
  }
  
  .app-title {
    font-size: 22px;
  }
  
  .app-subtitle {
    font-size: 12px;
  }
  
  .auth-tabs {
    margin-bottom: 14px;
  }
  
  .auth-form {
    gap: 14px;
  }
  
  .info-text {
    margin-top: 14px;
  }
  
  .page-footer {
    padding: 14px 20px;
  }
  
  .page-footer p {
    font-size: 12px;
    letter-spacing: 0.6px;
    font-weight: 600;
  }
}

/* ===== 大屏幕优化 ===== */
@media (min-width: 768px) {
  .login-page {
    padding: 20px 20px 100px 20px;
  }
  
  .login-container {
    padding: 36px 32px;
    max-width: 420px;
    margin-bottom: 25px;
  }
  
  .logo-icon {
    font-size: 60px;
  }
  
  .app-title {
    font-size: 30px;
  }
  
  .page-footer {
    padding: 28px 40px;
    background: linear-gradient(to top, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.25) 70%, transparent);
  }
  
  .page-footer p {
    font-size: 16px;
    font-weight: 600;
    letter-spacing: 1.4px;
    text-shadow: 0 2px 12px rgba(0, 0, 0, 0.7);
  }
}

/* ===== 超大屏幕优化 ===== */
@media (min-width: 1200px) {
  .login-container {
    padding: 40px 36px;
    max-width: 440px;
  }
  
  .page-footer {
    padding: 32px 40px;
  }
  
  .page-footer p {
    font-size: 17px;
    letter-spacing: 1.6px;
  }
}
</style>
