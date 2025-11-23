import { ref, computed, onMounted, onUnmounted } from 'vue'

export function useVirtualScroll(items, itemHeight = 80) {
  const containerRef = ref(null)
  const scrollTop = ref(0)
  const containerHeight = ref(600)
  
  const visibleStart = computed(() => {
    return Math.floor(scrollTop.value / itemHeight)
  })
  
  const visibleEnd = computed(() => {
    return Math.ceil((scrollTop.value + containerHeight.value) / itemHeight)
  })
  
  const visibleItems = computed(() => {
    return items.value.slice(
      Math.max(0, visibleStart.value - 5),
      Math.min(items.value.length, visibleEnd.value + 5)
    )
  })
  
  const totalHeight = computed(() => {
    return items.value.length * itemHeight
  })
  
  const offsetY = computed(() => {
    return Math.max(0, visibleStart.value - 5) * itemHeight
  })
  
  function handleScroll(event) {
    scrollTop.value = event.target.scrollTop
  }
  
  onMounted(() => {
    if (containerRef.value) {
      containerHeight.value = containerRef.value.clientHeight
    }
  })
  
  return {
    containerRef,
    visibleItems,
    totalHeight,
    offsetY,
    handleScroll
  }
}
