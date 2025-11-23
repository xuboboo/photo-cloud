import { supabase } from './supabase'
import { getUser } from './auth'
import { getUserStorageStats } from './security'

/**
 * 清理文件名，移除特殊字符和中文
 */
function sanitizeFileName(fileName) {
  // 获取文件扩展名
  const lastDotIndex = fileName.lastIndexOf('.')
  const extension = lastDotIndex > -1 ? fileName.substring(lastDotIndex) : ''
  const nameWithoutExt = lastDotIndex > -1 ? fileName.substring(0, lastDotIndex) : fileName
  
  // 清理文件名：只保留字母、数字、连字符和下划线
  let cleanName = nameWithoutExt
    .replace(/[^\w\s-]/g, '') // 移除特殊字符
    .replace(/\s+/g, '-')     // 空格转为连字符
    .replace(/--+/g, '-')     // 多个连字符合并为一个
    .toLowerCase()
  
  // 如果清理后为空（比如全是中文），使用时间戳
  if (!cleanName || cleanName.length === 0) {
    cleanName = `file-${Date.now()}`
  }
  
  // 限制长度
  if (cleanName.length > 100) {
    cleanName = cleanName.substring(0, 100)
  }
  
  return cleanName + extension
}

/**
 * 上传文件到 Supabase Storage
 */
export async function uploadFile(file, type, originalName = null, onProgress = null) {
  try {
    // 直接从 Supabase 获取用户，更可靠
    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError || !user) {
      throw new Error('用户未登录，请先登录')
    }

    // 检查存储限制
    try {
      const storageStats = await getUserStorageStats(user.id)
      
      if (storageStats.is_full) {
        throw new Error(
          `存储空间已满！您已使用 ${formatFileSize(storageStats.storage_used)} / ${formatFileSize(storageStats.storage_quota)}。` +
          `\n\n请联系管理员 ${storageStats.upgrade_contact} 升级存储容量。`
        )
      }
      
      // 检查上传后是否会超出
      if (storageStats.remaining_storage < file.size) {
        throw new Error(
          `存储空间不足！` +
          `\n当前已使用：${formatFileSize(storageStats.storage_used)}` +
          `\n剩余空间：${formatFileSize(storageStats.remaining_storage)}` +
          `\n文件大小：${formatFileSize(file.size)}` +
          `\n\n请联系管理员 ${storageStats.upgrade_contact} 升级存储容量。`
        )
      }
    } catch (storageError) {
      // 如果是存储限制错误，直接抛出
      if (storageError.message.includes('存储空间')) {
        throw storageError
      }
      // 其他错误记录但继续（避免阻塞正常用户）
      console.error('Storage check error:', storageError)
    }

    // 清理文件名
    const cleanFileName = sanitizeFileName(file.name)
    const timestamp = Date.now()
    const filePath = `${type}/${user.id}/${timestamp}-${cleanFileName}`

    // 模拟上传进度（Supabase SDK 不直接支持进度回调）
    if (onProgress) {
      onProgress(0)
      // 模拟进度更新
      const progressInterval = setInterval(() => {
        const currentProgress = Math.min(90, Math.random() * 30 + 60)
        onProgress(currentProgress)
      }, 200)
      
      // 上传到 Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('private-files')
        .upload(filePath, file)

      clearInterval(progressInterval)
      onProgress(100)

      if (uploadError) throw uploadError
      
      // 记录到数据库
      const { data: dbData, error: dbError } = await supabase
        .from('files')
        .insert({
          user_id: user.id,
          path: filePath,
          name: file.name,
          original_name: originalName || file.name,
          size: file.size,
          type
        })
        .select()
        .single()

      if (dbError) throw dbError

      return { uploadData, dbData }
    } else {
      // 没有进度回调时的原始逻辑
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('private-files')
        .upload(filePath, file)

      if (uploadError) throw uploadError

      // 记录到数据库
      const { data: dbData, error: dbError } = await supabase
        .from('files')
        .insert({
          user_id: user.id,
          path: filePath,
          name: file.name,
          original_name: originalName || file.name,
          size: file.size,
          type
        })
        .select()
        .single()

      if (dbError) throw dbError

      return { uploadData, dbData }
    }
  } catch (error) {
    console.error('Upload error:', error)
    throw error
  }
}

/**
 * 获取用户的文件列表
 */
export async function getFiles() {
  try {
    // 直接从 Supabase 获取用户
    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError || !user) {
      // 用户未登录，返回空数组而不是抛出错误
      return []
    }

    const { data, error } = await supabase
      .from('files')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (error) throw error

    return data || []
  } catch (error) {
    console.error('Get files error:', error)
    throw error
  }
}

/**
 * 获取文件的签名 URL（用于下载/预览）
 */
export async function getSignedUrl(path, expiresIn = 3600) {
  try {
    const { data, error } = await supabase.storage
      .from('private-files')
      .createSignedUrl(path, expiresIn)

    if (error) throw error

    return data.signedUrl
  } catch (error) {
    console.error('Get signed URL error:', error)
    throw error
  }
}

/**
 * 删除文件
 */
export async function deleteFile(fileId, filePath) {
  try {
    // 从 Storage 删除
    const { error: storageError } = await supabase.storage
      .from('private-files')
      .remove([filePath])

    if (storageError) throw storageError

    // 从数据库删除
    const { error: dbError } = await supabase
      .from('files')
      .delete()
      .eq('id', fileId)

    if (dbError) throw dbError

    return true
  } catch (error) {
    console.error('Delete file error:', error)
    throw error
  }
}

/**
 * 格式化文件大小
 * @param {number} bytes - 字节数
 * @returns {string} 格式化后的大小
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

/**
 * 根据 ID 获取单个文件信息
 */
export async function getFileById(fileId) {
  try {
    const { data, error } = await supabase
      .from('files')
      .select('*')
      .eq('id', fileId)
      .single()

    if (error) throw error

    return data
  } catch (error) {
    console.error('Get file by ID error:', error)
    throw error
  }
}
