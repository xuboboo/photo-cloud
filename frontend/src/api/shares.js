import { supabase } from './supabase'
import { getUser } from './auth'

/**
 * 生成随机分享 token
 */
function generateShareToken() {
  return Math.random().toString(36).substring(2, 15) + 
         Math.random().toString(36).substring(2, 15)
}

/**
 * 创建文件分享
 */
export async function createFileShare(fileId, options = {}) {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) {
      throw new Error('用户未登录')
    }
    
    const shareToken = generateShareToken()
    
    const { data, error } = await supabase
      .from('file_shares')
      .insert({
        file_id: fileId,
        user_id: user.id,
        share_token: shareToken,
        password: options.password || null,
        expires_at: options.expiresAt || null,
        max_downloads: options.maxDownloads || null
      })
      .select()
      .single()
    
    if (error) throw error
    
    return data
  } catch (error) {
    console.error('Create file share error:', error)
    throw error
  }
}

/**
 * 获取文件的分享列表
 */
export async function getFileShares(fileId) {
  try {
    const { data, error } = await supabase
      .from('file_shares')
      .select('*')
      .eq('file_id', fileId)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Get file shares error:', error)
    throw error
  }
}

/**
 * 获取用户的所有分享
 */
export async function getUserShares() {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) {
      return []
    }
    
    const { data, error } = await supabase
      .from('file_shares')
      .select(`
        *,
        files (
          id,
          name,
          type,
          size
        )
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Get user shares error:', error)
    throw error
  }
}

/**
 * 通过 token 获取分享信息
 */
export async function getShareByToken(token, password = null) {
  try {
    let query = supabase
      .from('file_shares')
      .select(`
        *,
        files (
          id,
          name,
          type,
          size,
          path
        )
      `)
      .eq('share_token', token)
      .eq('is_active', true)
      .single()
    
    const { data, error } = await query
    
    if (error) throw error
    
    // 检查是否过期
    if (data.expires_at && new Date(data.expires_at) < new Date()) {
      throw new Error('分享链接已过期')
    }
    
    // 检查下载次数
    if (data.max_downloads && data.download_count >= data.max_downloads) {
      throw new Error('分享链接已达到最大下载次数')
    }
    
    // 检查密码
    if (data.password && data.password !== password) {
      throw new Error('密码错误')
    }
    
    return data
  } catch (error) {
    console.error('Get share by token error:', error)
    throw error
  }
}

/**
 * 增加分享下载次数
 */
export async function incrementShareDownload(shareId) {
  try {
    const { error } = await supabase.rpc('increment_share_download', {
      share_id: shareId
    })
    
    if (error) {
      // 如果 RPC 不存在，使用普通更新
      const { error: updateError } = await supabase
        .from('file_shares')
        .update({ download_count: supabase.raw('download_count + 1') })
        .eq('id', shareId)
      
      if (updateError) throw updateError
    }
  } catch (error) {
    console.error('Increment share download error:', error)
    // 不抛出错误，避免影响下载
  }
}

/**
 * 删除分享
 */
export async function deleteShare(shareId) {
  try {
    const { error } = await supabase
      .from('file_shares')
      .delete()
      .eq('id', shareId)
    
    if (error) throw error
  } catch (error) {
    console.error('Delete share error:', error)
    throw error
  }
}

/**
 * 更新分享状态
 */
export async function updateShareStatus(shareId, isActive) {
  try {
    const { data, error } = await supabase
      .from('file_shares')
      .update({ is_active: isActive })
      .eq('id', shareId)
      .select()
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Update share status error:', error)
    throw error
  }
}

/**
 * 生成分享链接
 */
export function generateShareLink(token) {
  const baseUrl = window.location.origin
  return `${baseUrl}/share/${token}`
}
