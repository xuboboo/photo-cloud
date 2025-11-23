<template>
  <div class="blog-detail">
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>Loading article...</p>
    </div>

    <div v-else-if="!post" class="not-found">
      <h1>404</h1>
      <p>Article not found</p>
      <router-link to="/blog" class="back-btn">← Back to Blog</router-link>
    </div>

    <article v-else class="article">
      <!-- Hero Section -->
      <header class="article-hero">
        <div class="container">
          <router-link to="/blog" class="back-link">← Back to Blog</router-link>
          <h1 class="article-title">{{ post.title }}</h1>
          <div class="article-meta">
            <span class="author">{{ post.author }}</span>
            <span class="separator">•</span>
            <span class="date">{{ formatDate(post.date) }}</span>
            <span class="separator">•</span>
            <span class="read-time">{{ post.readTime }}</span>
          </div>
          <div class="article-tags">
            <span v-for="tag in post.tags" :key="tag" class="tag">{{ tag }}</span>
          </div>
        </div>
      </header>

      <!-- Featured Image -->
      <div class="featured-image" v-if="post.image">
        <img :src="post.image" :alt="post.title" />
      </div>

      <!-- Article Content -->
      <div class="article-content container">
        <div class="content" v-html="renderedContent"></div>
      </div>

      <!-- Social Share -->
      <div class="article-share container">
        <h3>Share this article</h3>
        <SocialShare 
          :url="shareUrl" 
          :title="post.title" 
          :description="post.excerpt"
        />
      </div>

      <!-- Related Articles -->
      <div class="related-articles container" v-if="relatedPosts.length > 0">
        <h2>Related Articles</h2>
        <div class="articles-grid">
          <router-link 
            v-for="related in relatedPosts" 
            :key="related.id"
            :to="`/blog/${related.slug}`"
            class="article-card"
          >
            <img :src="related.image" :alt="related.title" />
            <div class="card-content">
              <span class="category">{{ related.category }}</span>
              <h3>{{ related.title }}</h3>
              <p>{{ related.excerpt }}</p>
              <div class="card-meta">
                <span>{{ related.readTime }}</span>
                <span>{{ formatDate(related.date) }}</span>
              </div>
            </div>
          </router-link>
        </div>
      </div>
    </article>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { marked } from 'marked'
import { getPostBySlug, getRelatedPosts } from '../data/blog'
import SocialShare from '../components/SocialShare.vue'

const route = useRoute()
const loading = ref(true)
const post = ref(null)

// 获取文章
const loadPost = async () => {
  loading.value = true
  const slug = route.params.slug
  
  try {
    post.value = getPostBySlug(slug)
    
    // 设置SEO
    if (post.value) {
      document.title = `${post.value.title} | Photo Cloud Blog`
      
      // Meta description
      let metaDesc = document.querySelector('meta[name="description"]')
      if (!metaDesc) {
        metaDesc = document.createElement('meta')
        metaDesc.name = 'description'
        document.head.appendChild(metaDesc)
      }
      metaDesc.content = post.value.excerpt
      
      // Meta keywords
      let metaKeywords = document.querySelector('meta[name="keywords"]')
      if (!metaKeywords) {
        metaKeywords = document.createElement('meta')
        metaKeywords.name = 'keywords'
        document.head.appendChild(metaKeywords)
      }
      metaKeywords.content = post.value.tags.join(', ')
    }
  } catch (error) {
    console.error('Error loading post:', error)
    post.value = null
  } finally {
    loading.value = false
  }
}

// 渲染Markdown内容
const renderedContent = computed(() => {
  if (!post.value || !post.value.content) return ''
  
  // 配置marked选项
  marked.setOptions({
    breaks: true,
    gfm: true,
    headerIds: true,
    mangle: false
  })
  
  return marked(post.value.content)
})

// 相关文章
const relatedPosts = computed(() => {
  if (!post.value) return []
  return getRelatedPosts(post.value, 3)
})

// 分享URL
const shareUrl = computed(() => {
  if (typeof window === 'undefined') return ''
  return window.location.href
})

// 格式化日期
const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  })
}

// 监听路由变化
watch(() => route.params.slug, () => {
  if (route.params.slug) {
    loadPost()
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
})

onMounted(() => {
  loadPost()
})
</script>

<style scoped>
.blog-detail {
  min-height: 100vh;
  background: #f8f9fa;
}

.loading, .not-found {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
  padding: 2rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.not-found h1 {
  font-size: 4rem;
  margin: 0;
  color: #667eea;
}

.back-btn {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  background: #667eea;
  color: white;
  text-decoration: none;
  border-radius: 8px;
  transition: background 0.3s;
}

.back-btn:hover {
  background: #5568d3;
}

/* Article Hero */
.article-hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 4rem 2rem 3rem;
}

.container {
  max-width: 800px;
  margin: 0 auto;
}

.back-link {
  color: white;
  text-decoration: none;
  opacity: 0.9;
  font-size: 0.9rem;
  transition: opacity 0.3s;
}

.back-link:hover {
  opacity: 1;
}

.article-title {
  font-size: 2.5rem;
  margin: 1.5rem 0 1rem;
  line-height: 1.2;
}

.article-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  opacity: 0.9;
  margin-bottom: 1rem;
}

.separator {
  opacity: 0.5;
}

.article-tags {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.tag {
  background: rgba(255, 255, 255, 0.2);
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.85rem;
}

/* Featured Image */
.featured-image {
  max-width: 1200px;
  margin: -2rem auto 3rem;
  padding: 0 2rem;
}

.featured-image img {
  width: 100%;
  height: auto;
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

/* Article Content */
.article-content {
  padding: 2rem;
  margin-bottom: 3rem;
}

.content {
  background: white;
  padding: 3rem;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  line-height: 1.8;
  font-size: 1.05rem;
  color: #333;
}

.content :deep(h1),
.content :deep(h2),
.content :deep(h3),
.content :deep(h4),
.content :deep(h5),
.content :deep(h6) {
  margin-top: 2rem;
  margin-bottom: 1rem;
  color: #2c3e50;
  font-weight: 600;
}

.content :deep(h1) { font-size: 2rem; }
.content :deep(h2) { font-size: 1.75rem; }
.content :deep(h3) { font-size: 1.5rem; }
.content :deep(h4) { font-size: 1.25rem; }

.content :deep(p) {
  margin-bottom: 1.5rem;
}

.content :deep(ul),
.content :deep(ol) {
  margin-bottom: 1.5rem;
  padding-left: 2rem;
}

.content :deep(li) {
  margin-bottom: 0.5rem;
}

.content :deep(a) {
  color: #667eea;
  text-decoration: none;
  border-bottom: 1px solid transparent;
  transition: border-color 0.3s;
}

.content :deep(a:hover) {
  border-bottom-color: #667eea;
}

.content :deep(code) {
  background: #f5f5f5;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
}

.content :deep(pre) {
  background: #2d2d2d;
  color: #f8f8f2;
  padding: 1.5rem;
  border-radius: 8px;
  overflow-x: auto;
  margin: 1.5rem 0;
}

.content :deep(pre code) {
  background: none;
  padding: 0;
  color: inherit;
}

.content :deep(blockquote) {
  border-left: 4px solid #667eea;
  padding-left: 1.5rem;
  margin: 1.5rem 0;
  color: #666;
  font-style: italic;
}

.content :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  margin: 1.5rem 0;
}

.content :deep(table) {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
}

.content :deep(th),
.content :deep(td) {
  border: 1px solid #ddd;
  padding: 0.75rem;
  text-align: left;
}

.content :deep(th) {
  background: #f5f5f5;
  font-weight: 600;
}

.content :deep(hr) {
  border: none;
  border-top: 2px solid #eee;
  margin: 2rem 0;
}

/* Social Share */
.article-share {
  padding: 2rem;
  margin-bottom: 3rem;
}

.article-share h3 {
  margin-bottom: 1rem;
  color: #2c3e50;
}

/* Related Articles */
.related-articles {
  padding: 2rem;
  margin-bottom: 3rem;
}

.related-articles h2 {
  margin-bottom: 2rem;
  color: #2c3e50;
}

.articles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 2rem;
}

.article-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  text-decoration: none;
  color: inherit;
  transition: transform 0.3s, box-shadow 0.3s;
}

.article-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
}

.article-card img {
  width: 100%;
  height: 200px;
  object-fit: cover;
}

.card-content {
  padding: 1.5rem;
}

.category {
  display: inline-block;
  background: #667eea;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.75rem;
  margin-bottom: 0.75rem;
}

.card-content h3 {
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.card-content p {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 1rem;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-meta {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  color: #999;
}

/* Responsive */
@media (max-width: 768px) {
  .article-hero {
    padding: 2rem 1rem;
  }

  .article-title {
    font-size: 1.75rem;
  }

  .featured-image {
    margin: -1rem auto 2rem;
    padding: 0 1rem;
  }

  .content {
    padding: 1.5rem;
    font-size: 1rem;
  }

  .articles-grid {
    grid-template-columns: 1fr;
  }
}
</style>
