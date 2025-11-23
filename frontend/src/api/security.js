/**
 * 安全相关API
 */
import { supabase } from './supabase'

/**
 * 检查速率限制
 * @param {string} identifier - 识别符（IP或用户ID）
 * @param {string} action - 操作类型
 * @returns {Promise<{allowed: boolean, message?: string}>}
 */
export async function checkRateLimit(identifier, action) {
  try {
    const { data, error } = await supabase.rpc('check_rate_limit', {
      p_identifier: identifier,
      p_action: action
    })
    
    if (error) throw error
    
    return {
      allowed: data,
      message: data ? null : '操作过于频繁，请稍后再试'
    }
  } catch (error) {
    console.error('Check rate limit error:', error)
    return { allowed: true } // 出错时允许通过，避免阻塞正常用户
  }
}

/**
 * 记录安全事件
 * @param {string} action - 操作类型
 * @param {object} details - 详细信息
 * @param {string} severity - 严重程度
 */
export async function logSecurityEvent(action, details = {}, severity = 'info') {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    await supabase.rpc('log_security_event', {
      p_user_id: user?.id || null,
      p_action: action,
      p_details: details,
      p_severity: severity
    })
  } catch (error) {
    console.error('Log security event error:', error)
  }
}

/**
 * 获取用户存储统计
 * @param {string} userId - 用户ID
 * @returns {Promise<object>}
 */
export async function getUserStorageStats(userId) {
  try {
    const { data, error } = await supabase.rpc('get_user_storage_stats', {
      p_user_id: userId
    })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Get storage stats error:', error)
    throw error
  }
}

/**
 * 管理员设置用户配额
 * @param {string} userId - 目标用户ID
 * @param {number} newQuota - 新配额（字节）
 * @returns {Promise<object>}
 */
export async function adminSetUserQuota(userId, newQuota) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    const { data, error } = await supabase.rpc('admin_set_user_quota', {
      p_user_id: userId,
      p_new_quota: newQuota,
      p_admin_id: user.id
    })
    
    if (error) throw error
    
    if (!data.success) {
      throw new Error(data.error)
    }
    
    return data
  } catch (error) {
    console.error('Admin set quota error:', error)
    throw error
  }
}

/**
 * 检查分享访问权限
 * @param {string} shareToken - 分享令牌
 * @param {string} password - 密码（可选）
 * @returns {Promise<object>}
 */
export async function checkShareAccess(shareToken, password = null) {
  try {
    const { data, error } = await supabase.rpc('check_share_access', {
      p_share_token: shareToken,
      p_password: password
    })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Check share access error:', error)
    throw error
  }
}

/**
 * 创建安全分享
 * @param {string} fileId - 文件ID
 * @param {object} options - 分享选项
 * @returns {Promise<object>}
 */
export async function createSecureShare(fileId, options = {}) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    const shareToken = generateShareToken()
    
    const shareData = {
      file_id: fileId,
      user_id: user.id,
      share_token: shareToken,
      password: options.password || null,
      expires_at: options.expiresAt || null,
      max_downloads: options.maxDownloads || null,
      is_active: true
    }
    
    const { data, error } = await supabase
      .from('file_shares')
      .insert(shareData)
      .select()
      .single()
    
    if (error) throw error
    
    // 记录安全事件
    await logSecurityEvent('share_created', {
      file_id: fileId,
      has_password: !!options.password,
      has_expiry: !!options.expiresAt,
      has_download_limit: !!options.maxDownloads
    })
    
    return data
  } catch (error) {
    console.error('Create secure share error:', error)
    throw error
  }
}

/**
 * 生成分享令牌
 * @returns {string}
 */
function generateShareToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let token = ''
  const array = new Uint8Array(32)
  crypto.getRandomValues(array)
  
  for (let i = 0; i < 32; i++) {
    token += chars[array[i] % chars.length]
  }
  
  return token
}

/**
 * 获取安全日志
 * @param {object} filters - 过滤条件
 * @returns {Promise<Array>}
 */
export async function getSecurityLogs(filters = {}) {
  try {
    let query = supabase
      .from('security_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(filters.limit || 100)
    
    if (filters.userId) {
      query = query.eq('user_id', filters.userId)
    }
    
    if (filters.action) {
      query = query.eq('action', filters.action)
    }
    
    if (filters.severity) {
      query = query.eq('severity', filters.severity)
    }
    
    const { data, error } = await query
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Get security logs error:', error)
    throw error
  }
}

/**
 * 获取系统配置
 * @param {string} key - 配置键
 * @returns {Promise<any>}
 */
export async function getSystemConfig(key) {
  try {
    const { data, error } = await supabase
      .from('system_config')
      .select('value')
      .eq('key', key)
      .single()
    
    if (error) throw error
    return data.value
  } catch (error) {
    console.error('Get system config error:', error)
    throw error
  }
}

/**
 * 更新系统配置（仅管理员）
 * @param {string} key - 配置键
 * @param {any} value - 配置值
 * @returns {Promise<void>}
 */
export async function updateSystemConfig(key, value) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    const { error } = await supabase
      .from('system_config')
      .update({
        value,
        updated_at: new Date().toISOString(),
        updated_by: user.id
      })
      .eq('key', key)
    
    if (error) throw error
    
    await logSecurityEvent('config_updated', { key, value }, 'info')
  } catch (error) {
    console.error('Update system config error:', error)
    throw error
  }
}
