<template>
  <MobileLayout title="上传文件" :show-back="true">
    <!-- 移动端内容 -->
    <div class="upload-mobile-content">
      <FileUploader @upload-success="handleUploadSuccess" @upload-error="handleUploadError" />
    </div>
    
    <!-- 桌面端内容 -->
    <template #desktop>
      <div class="upload-page">
        <div class="upload-header">
          <button @click="handleBack" class="btn-back">← 返回</button>
          <h1>上传文件</h1>
        </div>

        <div class="upload-content">
          <FileUploader @upload-success="handleUploadSuccess" @upload-error="handleUploadError" />
        </div>
        
        <Footer />
      </div>
    </template>
  </MobileLayout>
</template>

<script setup>
import { useRouter } from 'vue-router'
import MobileLayout from '../layouts/MobileLayout.vue'
import FileUploader from '../components/FileUploader.vue'
import Footer from '../components/Footer.vue'

const router = useRouter()

function handleUploadSuccess() {
  alert('上传成功！')
  setTimeout(() => {
    router.push('/dashboard')
  }, 1000)
}

function handleUploadError(error) {
  console.error('Upload error:', error)
}

function handleBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/dashboard')
  }
}

</script>

<style scoped>
.upload-page {
  min-height: 100vh;
  background-color: #f7fafc;
  padding: 20px;
}

.upload-header {
  max-width: 1200px;
  margin: 0 auto 40px;
  display: flex;
  align-items: center;
  gap: 20px;
}

.upload-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
  color: #2d3748;
}

.btn-back {
  padding: 10px 20px;
  background-color: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #2d3748;
  transition: all 0.2s ease;
}

.btn-back:hover {
  background-color: #edf2f7;
}

.upload-content {
  max-width: 1200px;
  margin: 0 auto;
}

/* 移动端内容 */
.upload-mobile-content {
  padding: 1.5rem 1rem;
}

/* 移动端优化 */
@media (max-width: 768px) {
  .upload-page {
    padding: 1rem;
  }
  
  .upload-header {
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
  }
  
  .upload-header h1 {
    font-size: 1.5rem;
  }
  
  .btn-back {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
  }
}
</style>
