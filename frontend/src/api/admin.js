import { supabase } from './supabase'

/**
 * 获取所有用户列表（管理员）
 */
export async function getAllUsers() {
  try {
    const { data, error } = await supabase
      .from('user_statistics')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Get all users error:', error)
    throw error
  }
}

/**
 * 管理员手动验证用户邮箱
 */
export async function adminVerifyUserEmail(userId) {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id
    
    const { data, error } = await supabase.rpc('admin_verify_user_email', {
      p_admin_id: adminId,
      p_target_user_id: userId
    })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Verify user email error:', error)
    throw error
  }
}

/**
 * 管理员重发验证邮件
 */
export async function adminResendVerificationEmail(userId) {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id
    
    const { data, error } = await supabase.rpc('admin_resend_verification_email', {
      p_admin_id: adminId,
      p_target_user_id: userId
    })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Resend verification email error:', error)
    throw error
  }
}

/**
 * 获取未验证用户列表
 */
export async function getUnverifiedUsers() {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id
    
    const { data, error } = await supabase.rpc('get_unverified_users', {
      p_admin_id: adminId
    })
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Get unverified users error:', error)
    throw error
  }
}

/**
 * 获取邮箱验证统计
 */
export async function getEmailVerificationStats() {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id
    
    const { data, error } = await supabase.rpc('get_email_verification_stats', {
      p_admin_id: adminId
    })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Get email verification stats error:', error)
    throw error
  }
}

/**
 * 获取用户详情
 */
export async function getUserProfile(userId) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Get user profile error:', error)
    throw error
  }
}

/**
 * 更新用户状态（启用/禁用）
 */
export async function updateUserStatus(userId, isActive) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({ is_active: isActive })
      .eq('id', userId)
      .select()
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Update user status error:', error)
    throw error
  }
}

/**
 * 更新用户角色
 */
export async function updateUserRole(userId, role) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({ role })
      .eq('id', userId)
      .select()
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Update user role error:', error)
    throw error
  }
}

/**
 * 更新用户配额
 */
export async function updateUserQuota(userId, quota) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({ storage_quota: quota })
      .eq('id', userId)
      .select()
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Update user quota error:', error)
    throw error
  }
}

/**
 * 获取当前用户配置
 */
export async function getCurrentUserProfile() {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) throw new Error('未登录')
    
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', user.id)
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Get current user profile error:', error)
    throw error
  }
}

/**
 * 更新当前用户配置
 */
export async function updateCurrentUserProfile(updates) {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) throw new Error('未登录')
    
    const { data, error } = await supabase
      .from('user_profiles')
      .update(updates)
      .eq('id', user.id)
      .select()
      .single()
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('Update current user profile error:', error)
    throw error
  }
}

/**
 * 获取活动日志
 */
export async function getActivityLogs(userId = null, limit = 50) {
  try {
    let query = supabase
      .from('activity_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    
    if (userId) {
      query = query.eq('user_id', userId)
    }
    
    const { data, error } = await query
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Get activity logs error:', error)
    throw error
  }
}

/**
 * 记录活动日志
 */
export async function logActivity(action, resourceType = null, resourceId = null, details = null) {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) return
    
    const { error } = await supabase
      .from('activity_logs')
      .insert({
        user_id: user.id,
        action,
        resource_type: resourceType,
        resource_id: resourceId,
        details
      })
    
    if (error) throw error
  } catch (error) {
    console.error('Log activity error:', error)
    // 不抛出错误，避免影响主要功能
  }
}

/**
 * 检查用户是否是管理员
 */
export async function isAdmin() {
  try {
    const profile = await getCurrentUserProfile()
    return profile && ['admin', 'super_admin'].includes(profile.role)
  } catch (error) {
    return false
  }
}

/**
 * 检查用户是否是超级管理员
 */
export async function isSuperAdmin() {
  try {
    const profile = await getCurrentUserProfile()
    return profile && profile.role === 'super_admin'
  } catch (error) {
    return false
  }
}

/**
 * 删除用户及其所有数据（超级管理员功能）
 */
export async function deleteUser(userId) {
  try {
    // 1. 先获取用户的所有文件路径（用于删除 Storage 中的文件）
    const { data: filePaths, error: pathsError } = await supabase
      .rpc('get_user_file_paths', { target_user_id: userId })
    
    if (pathsError) {
      console.error('获取文件路径失败:', pathsError)
      // 继续执行，即使无法获取文件路径
    }

    // 2. 删除 Storage 中的所有文件
    if (filePaths && filePaths.length > 0) {
      const paths = filePaths.map(item => item.file_path)
      
      // 批量删除文件
      const { error: storageError } = await supabase.storage
        .from('files')
        .remove(paths)
      
      if (storageError) {
        console.error('删除 Storage 文件失败:', storageError)
        // 继续执行，即使部分文件删除失败
      }
    }

    // 3. 使用数据库函数删除用户及其所有数据
    // 这个函数会删除：文件夹、文件记录、分享、活动日志、用户配置、认证用户
    const { data, error } = await supabase
      .rpc('delete_user_completely', { target_user_id: userId })
    
    if (error) throw error
    
    if (data && !data.success) {
      throw new Error(data.error || '删除用户失败')
    }

    return {
      success: true,
      message: '用户及所有数据已删除',
      statistics: data?.statistics || {}
    }
  } catch (error) {
    console.error('删除用户失败:', error)
    throw new Error('删除用户失败：' + error.message)
  }
}

/**
 * 获取邮箱黑名单列表
 */
export async function getEmailBlacklist() {
  try {
    const { data, error } = await supabase
      .from('blacklist_details')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  } catch (error) {
    console.error('获取黑名单失败:', error)
    throw error
  }
}

/**
 * 添加邮箱到黑名单
 */
export async function addEmailToBlacklist(email, reason = null) {
  try {
    const { data, error } = await supabase
      .rpc('add_email_to_blacklist', {
        target_email: email,
        block_reason: reason
      })
    
    if (error) throw error
    
    if (data && !data.success) {
      throw new Error(data.error || '添加黑名单失败')
    }
    
    return data
  } catch (error) {
    console.error('添加黑名单失败:', error)
    throw error
  }
}

/**
 * 从黑名单移除邮箱
 */
export async function removeEmailFromBlacklist(email) {
  try {
    const { data, error } = await supabase
      .rpc('remove_email_from_blacklist', {
        target_email: email
      })
    
    if (error) throw error
    
    if (data && !data.success) {
      throw new Error(data.error || '移除黑名单失败')
    }
    
    return data
  } catch (error) {
    console.error('移除黑名单失败:', error)
    throw error
  }
}

/**
 * 批量添加邮箱到黑名单
 */
export async function batchAddEmailsToBlacklist(emails, reason = null) {
  try {
    const { data, error } = await supabase
      .rpc('batch_add_emails_to_blacklist', {
        emails_json: emails,
        block_reason: reason
      })
    
    if (error) throw error
    
    if (data && !data.success) {
      throw new Error(data.error || '批量添加失败')
    }
    
    return data
  } catch (error) {
    console.error('批量添加黑名单失败:', error)
    throw error
  }
}

/**
 * 检查邮箱是否在黑名单中
 */
export async function checkEmailBlacklisted(email) {
  try {
    const { data, error } = await supabase
      .rpc('is_email_blacklisted', {
        check_email: email
      })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('检查黑名单失败:', error)
    return false
  }
}

/**
 * 注册前检查邮箱（包含黑名单检查）
 */
export async function checkEmailBeforeSignup(email) {
  try {
    const { data, error } = await supabase
      .rpc('check_email_before_signup', {
        check_email: email
      })
    
    if (error) throw error
    return data
  } catch (error) {
    console.error('检查邮箱失败:', error)
    return { allowed: true, message: '检查失败，允许继续' }
  }
}

/**
 * 获取黑名单统计信息
 */
export async function getBlacklistStats() {
  try {
    const { data, error } = await supabase
      .rpc('get_blacklist_stats')
    
    if (error) throw error
    
    if (data && !data.success) {
      throw new Error(data.error || '获取统计失败')
    }
    
    return data
  } catch (error) {
    console.error('获取黑名单统计失败:', error)
    throw error
  }
}
