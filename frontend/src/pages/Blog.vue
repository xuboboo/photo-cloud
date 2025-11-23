<template>
  <div class="blog-page">
    <!-- Hero Section -->
    <section class="blog-hero">
      <div class="container">
        <h1>{{ $t('blog.title', 'Photo Cloud Blog') }}</h1>
        <p>{{ $t('blog.subtitle', 'Tips, tutorials, and updates from the Photo Cloud team') }}</p>
        
        <!-- Search Bar -->
        <div class="search-bar">
          <input 
            v-model="searchQuery"
            type="text" 
            :placeholder="$t('blog.searchPlaceholder', 'Search articles...')"
            @input="handleSearch"
          />
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            <path d="M9 17A8 8 0 1 0 9 1a8 8 0 0 0 0 16zM18 18l-4.35-4.35" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </div>
      </div>
    </section>

    <!-- Categories -->
    <section class="categories">
      <div class="container">
        <button 
          v-for="category in categories" 
          :key="category"
          @click="filterByCategory(category)"
          :class="['category-btn', { active: selectedCategory === category }]"
        >
          {{ category }}
        </button>
      </div>
    </section>

    <!-- Blog Posts Grid -->
    <section class="blog-posts">
      <div class="container">
        <div v-if="filteredPosts.length === 0" class="no-results">
          <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="30" stroke="currentColor" stroke-width="2"/>
            <path d="M32 20v24M32 48h.01" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
          <h3>{{ $t('blog.noResults', 'No articles found') }}</h3>
          <p>{{ $t('blog.tryDifferent', 'Try different keywords or categories') }}</p>
        </div>

        <div v-else class="posts-grid">
          <article 
            v-for="post in filteredPosts" 
            :key="post.id"
            class="post-card"
            @click="goToPost(post.slug)"
          >
            <div class="post-image">
              <img :src="post.image" :alt="post.title" loading="lazy" />
              <span class="category-badge">{{ post.category }}</span>
            </div>
            
            <div class="post-content">
              <div class="post-meta">
                <span class="date">{{ formatDate(post.date) }}</span>
                <span class="read-time">{{ post.readTime }}</span>
              </div>
              
              <h2>{{ post.title }}</h2>
              <p>{{ post.excerpt }}</p>
              
              <div class="post-footer">
                <div class="tags">
                  <span v-for="tag in post.tags.slice(0, 3)" :key="tag" class="tag">
                    {{ tag }}
                  </span>
                </div>
                <button class="read-more">
                  {{ $t('blog.readMore', 'Read More') }}
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                    <path d="M6 3l5 5-5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                </button>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- Newsletter Section -->
    <section class="newsletter">
      <div class="container">
        <h2>{{ $t('blog.newsletter', 'Subscribe to our newsletter') }}</h2>
        <p>{{ $t('blog.newsletterDesc', 'Get the latest updates and tips delivered to your inbox') }}</p>
        <form @submit.prevent="handleSubscribe" class="newsletter-form">
          <input 
            v-model="email"
            type="email" 
            :placeholder="$t('blog.emailPlaceholder', 'Enter your email')"
            required
          />
          <button type="submit">{{ $t('blog.subscribe', 'Subscribe') }}</button>
        </form>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getAllPosts, getAllCategories } from '../data/blog'

const router = useRouter()

const searchQuery = ref('')
const selectedCategory = ref('All')
const email = ref('')

const allPosts = ref(getAllPosts())
const categories = ref(['All', ...getAllCategories()])

const filteredPosts = computed(() => {
  let posts = allPosts.value

  // Filter by category
  if (selectedCategory.value !== 'All') {
    posts = posts.filter(post => post.category === selectedCategory.value)
  }

  // Filter by search query
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    posts = posts.filter(post => 
      post.title.toLowerCase().includes(query) ||
      post.excerpt.toLowerCase().includes(query) ||
      post.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }

  return posts
})

function filterByCategory(category) {
  selectedCategory.value = category
}

function handleSearch() {
  // Debounce is handled by v-model
}

function goToPost(slug) {
  router.push(`/blog/${slug}`)
}

function formatDate(date) {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

function handleSubscribe() {
  // TODO: Implement newsletter subscription
  alert('Newsletter subscription coming soon!')
  email.value = ''
}

onMounted(() => {
  // SEO optimization
  document.title = 'Blog - Photo Cloud'
})
</script>

<style scoped>
.blog-page {
  min-height: 100vh;
  background: var(--gray-50);
}

/* Hero Section */
.blog-hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 80px 20px 60px;
  text-align: center;
}

.blog-hero h1 {
  font-size: 48px;
  font-weight: 800;
  margin-bottom: 16px;
}

.blog-hero p {
  font-size: 20px;
  opacity: 0.9;
  margin-bottom: 40px;
}

.search-bar {
  max-width: 600px;
  margin: 0 auto;
  position: relative;
}

.search-bar input {
  width: 100%;
  padding: 16px 50px 16px 20px;
  border: none;
  border-radius: var(--radius-lg);
  font-size: 16px;
  box-shadow: var(--shadow-lg);
}

.search-bar svg {
  position: absolute;
  right: 20px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--gray-400);
}

/* Categories */
.categories {
  padding: 30px 20px;
  background: white;
  border-bottom: 1px solid var(--gray-200);
  overflow-x: auto;
}

.categories .container {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: center;
}

.category-btn {
  padding: 10px 24px;
  border: 2px solid var(--gray-200);
  border-radius: var(--radius-full);
  background: white;
  cursor: pointer;
  font-weight: 600;
  transition: var(--transition);
  white-space: nowrap;
}

.category-btn:hover {
  border-color: var(--primary-500);
  color: var(--primary-600);
}

.category-btn.active {
  background: var(--primary-600);
  border-color: var(--primary-600);
  color: white;
}

/* Blog Posts */
.blog-posts {
  padding: 60px 20px;
}

.posts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 32px;
  max-width: 1200px;
  margin: 0 auto;
}

.post-card {
  background: white;
  border-radius: var(--radius-xl);
  overflow: hidden;
  box-shadow: var(--shadow);
  transition: var(--transition);
  cursor: pointer;
}

.post-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.post-image {
  position: relative;
  height: 220px;
  overflow: hidden;
}

.post-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: var(--transition);
}

.post-card:hover .post-image img {
  transform: scale(1.05);
}

.category-badge {
  position: absolute;
  top: 16px;
  right: 16px;
  padding: 6px 16px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: var(--radius-full);
  font-size: 12px;
  font-weight: 700;
  color: var(--primary-600);
  backdrop-filter: blur(10px);
}

.post-content {
  padding: 24px;
}

.post-meta {
  display: flex;
  gap: 16px;
  font-size: 14px;
  color: var(--gray-500);
  margin-bottom: 12px;
}

.post-content h2 {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 12px;
  color: var(--gray-900);
  line-height: 1.3;
}

.post-content > p {
  color: var(--gray-600);
  line-height: 1.6;
  margin-bottom: 20px;
}

.post-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.tags {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.tag {
  padding: 4px 12px;
  background: var(--gray-100);
  border-radius: var(--radius);
  font-size: 12px;
  color: var(--gray-600);
}

.read-more {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 16px;
  background: transparent;
  border: none;
  color: var(--primary-600);
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.read-more:hover {
  gap: 8px;
}

/* No Results */
.no-results {
  text-align: center;
  padding: 80px 20px;
  color: var(--gray-500);
}

.no-results svg {
  margin-bottom: 24px;
  opacity: 0.5;
}

.no-results h3 {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 8px;
  color: var(--gray-700);
}

/* Newsletter */
.newsletter {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 80px 20px;
  text-align: center;
}

.newsletter h2 {
  font-size: 36px;
  font-weight: 800;
  margin-bottom: 16px;
}

.newsletter p {
  font-size: 18px;
  opacity: 0.9;
  margin-bottom: 32px;
}

.newsletter-form {
  max-width: 500px;
  margin: 0 auto;
  display: flex;
  gap: 12px;
}

.newsletter-form input {
  flex: 1;
  padding: 14px 20px;
  border: none;
  border-radius: var(--radius-lg);
  font-size: 16px;
}

.newsletter-form button {
  padding: 14px 32px;
  background: white;
  color: var(--primary-600);
  border: none;
  border-radius: var(--radius-lg);
  font-weight: 700;
  cursor: pointer;
  transition: var(--transition);
}

.newsletter-form button:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

/* Responsive */
@media (max-width: 768px) {
  .blog-hero h1 {
    font-size: 32px;
  }

  .blog-hero p {
    font-size: 16px;
  }

  .posts-grid {
    grid-template-columns: 1fr;
  }

  .newsletter-form {
    flex-direction: column;
  }

  .categories .container {
    justify-content: flex-start;
  }
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}
</style>
