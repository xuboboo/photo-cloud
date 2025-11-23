<template>
  <div class="preview-page">
    <MarkdownViewer />
  </div>
</template>

<script setup>
import MarkdownViewer from '../components/MarkdownViewer.vue'

</script>

<style scoped>
.preview-page {
  min-height: 100vh;
  background-color: #f7fafc;
  padding: 20px;
}
</style>
