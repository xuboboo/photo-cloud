/**
 * 通用文件下载函数
 * 支持桌面端和移动端
 * 使用fetch+blob方式确保文件下载而不是在浏览器中打开
 */
export async function downloadFile(url, fileName) {
  try {
    // 统一使用fetch+blob方式下载，避免浏览器直接打开文件
    const response = await fetch(url, {
      mode: 'cors'
      // 不需要credentials，因为签名URL已经包含token
    })
    
    if (!response.ok) {
      throw new Error('下载失败: ' + response.statusText)
    }
    
    // 获取blob数据
    const blob = await response.blob()
    
    // 创建临时URL
    const blobUrl = URL.createObjectURL(blob)
    
    // 创建下载链接
    const link = document.createElement('a')
    link.href = blobUrl
    link.download = fileName
    link.style.display = 'none'
    
    // 触发下载
    document.body.appendChild(link)
    link.click()
    
    // 清理
    setTimeout(() => {
      document.body.removeChild(link)
      URL.revokeObjectURL(blobUrl)
    }, 100)
    
    return true
  } catch (error) {
    console.error('Download error:', error)
    
    // 如果fetch失败，回退到直接打开链接（作为最后的备选）
    try {
      const link = document.createElement('a')
      link.href = url
      link.download = fileName
      link.target = '_blank'
      link.rel = 'noopener noreferrer'
      link.style.display = 'none'
      
      document.body.appendChild(link)
      link.click()
      
      setTimeout(() => {
        document.body.removeChild(link)
      }, 100)
      
      return true
    } catch (fallbackError) {
      console.error('Fallback download also failed:', fallbackError)
      throw new Error('下载失败，请稍后重试')
    }
  }
}

/**
 * 检测是否为移动设备
 */
export function isMobileDevice() {
  return /iPhone|iPad|iPod|Android/i.test(navigator.userAgent)
}

/**
 * 显示移动端下载提示
 */
export function showMobileDownloadTip() {
  if (isMobileDevice()) {
    return '提示：在移动端，文件将在新标签页打开。长按图片可保存到相册，其他文件可通过浏览器的下载功能保存。'
  }
  return null
}
