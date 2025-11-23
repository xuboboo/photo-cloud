<template>
  <div class="markdown-viewer">
    <div v-if="loading" class="loading">加载中...</div>

    <div v-else-if="error" class="error">
      <p>{{ error }}</p>
      <button @click="router.back()" class="btn-back">返回</button>
    </div>

    <div v-else class="viewer-container">
      <div class="viewer-header">
        <button @click="router.back()" class="btn-back">← 返回</button>
        <h1 class="file-title">{{ fileName }}</h1>
        <button @click="downloadFile" class="btn-download">下载</button>
      </div>

      <div class="markdown-content prose" v-html="html"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getFileById, getSignedUrl } from '../api/files'
import { renderMarkdown } from '../utils/markdown'
import { downloadFile as downloadFileUtil } from '../utils/download'
import axios from 'axios'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const error = ref('')
const html = ref('')
const fileName = ref('')
const fileData = ref(null)

onMounted(async () => {
  await loadMarkdown()
})

async function loadMarkdown() {
  try {
    loading.value = true
    error.value = ''

    // 获取文件信息
    const file = await getFileById(route.params.id)
    fileData.value = file
    fileName.value = file.name

    // 获取签名 URL
    const url = await getSignedUrl(file.path)

    // 下载文件内容
    const response = await axios.get(url)
    const text = response.data

    // 渲染 Markdown
    html.value = renderMarkdown(text)
  } catch (err) {
    error.value = '加载失败：' + (err.message || '未知错误')
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function downloadFile() {
  try {
    const url = await getSignedUrl(fileData.value.path)
    const downloadFileName = fileData.value.original_name || fileData.value.name || fileName.value
    await downloadFileUtil(url, downloadFileName)
  } catch (err) {
    alert('下载失败：' + err.message)
  }
}

</script>

<style scoped>
.markdown-viewer {
  width: 100%;
  min-height: 100vh;
}

.loading,
.error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  color: #718096;
}

.error {
  color: #e53e3e;
}

.viewer-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 20px;
}

.viewer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 32px;
  padding-bottom: 16px;
  border-bottom: 2px solid #e2e8f0;
}

.file-title {
  flex: 1;
  margin: 0 20px;
  font-size: 24px;
  font-weight: 600;
  color: #2d3748;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.btn-back,
.btn-download {
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

.btn-back:hover,
.btn-download:hover {
  background-color: #edf2f7;
  border-color: #cbd5e0;
}

.markdown-content {
  background-color: #ffffff;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* Prose 样式 - Markdown 内容美化 */
.prose {
  color: #2d3748;
  line-height: 1.75;
}

.prose :deep(h1),
.prose :deep(h2),
.prose :deep(h3),
.prose :deep(h4),
.prose :deep(h5),
.prose :deep(h6) {
  color: #1a202c;
  font-weight: 600;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  line-height: 1.3;
}

.prose :deep(h1) {
  font-size: 2em;
  border-bottom: 2px solid #e2e8f0;
  padding-bottom: 0.3em;
}

.prose :deep(h2) {
  font-size: 1.5em;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 0.3em;
}

.prose :deep(h3) {
  font-size: 1.25em;
}

.prose :deep(p) {
  margin-top: 1em;
  margin-bottom: 1em;
}

.prose :deep(a) {
  color: #4299e1;
  text-decoration: none;
}

.prose :deep(a:hover) {
  text-decoration: underline;
}

.prose :deep(code) {
  background-color: #f7fafc;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-size: 0.9em;
  color: #e53e3e;
}

.prose :deep(pre) {
  background-color: #2d3748;
  color: #f7fafc;
  padding: 1em;
  border-radius: 6px;
  overflow-x: auto;
  margin: 1em 0;
}

.prose :deep(pre code) {
  background-color: transparent;
  color: inherit;
  padding: 0;
}

.prose :deep(blockquote) {
  border-left: 4px solid #4299e1;
  padding-left: 1em;
  color: #718096;
  margin: 1em 0;
}

.prose :deep(ul),
.prose :deep(ol) {
  padding-left: 2em;
  margin: 1em 0;
}

.prose :deep(li) {
  margin: 0.5em 0;
}

.prose :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 6px;
  margin: 1em 0;
}

.prose :deep(table) {
  width: 100%;
  border-collapse: collapse;
  margin: 1em 0;
}

.prose :deep(th),
.prose :deep(td) {
  border: 1px solid #e2e8f0;
  padding: 0.5em 1em;
  text-align: left;
}

.prose :deep(th) {
  background-color: #f7fafc;
  font-weight: 600;
}

.prose :deep(hr) {
  border: none;
  border-top: 2px solid #e2e8f0;
  margin: 2em 0;
}
</style>
