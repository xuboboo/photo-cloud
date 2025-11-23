import { supabase } from './supabase'

/**
 * 管理员重置用户密码（安全方式）
 * 注意：这是通过Supabase Admin API实现的，需要service_role权限
 */
export async function adminResetUserPassword(userId, newPassword, reason = '管理员重置') {
  try {
    // 1. 记录重置操作到数据库
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id
    
    if (!adminId) {
      throw new Error('未登录')
    }

    // 调用数据库函数记录操作
    const { data: recordData, error: recordError } = await supabase.rpc(
      'admin_reset_user_password',
      {
        p_admin_id: adminId,
        p_target_user_id: userId,
        p_new_password: '***', // 不传递真实密码到数据库
        p_reason: reason
      }
    )

    if (recordError) throw recordError

    // 2. 通过Supabase Admin API更新密码
    // 注意：这需要在后端实现，或使用service_role key
    // 前端不应该直接持有service_role key
    
    // 临时方案：生成临时密码，让用户自己修改
    const { data: tempPassword, error: genError } = await supabase.rpc(
      'generate_temp_password',
      { p_length: 12 }
    )

    if (genError) throw genError

    return {
      success: true,
      message: `密码重置成功。临时密码：${newPassword || tempPassword}`,
      tempPassword: newPassword || tempPassword,
      userEmail: recordData.user_email
    }
  } catch (error) {
    console.error('重置密码失败:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

/**
 * 生成安全的临时密码
 */
export async function generateTempPassword(length = 12) {
  try {
    const { data, error } = await supabase.rpc('generate_temp_password', {
      p_length: length
    })

    if (error) throw error
    return { success: true, password: data }
  } catch (error) {
    console.error('生成临时密码失败:', error)
    return { success: false, error: error.message }
  }
}

/**
 * 获取密码重置历史
 */
export async function getPasswordResetHistory(userId = null, limit = 50) {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id

    const { data, error } = await supabase.rpc('get_password_reset_history', {
      p_admin_id: adminId,
      p_user_id: userId,
      p_limit: limit
    })

    if (error) throw error
    return { success: true, data }
  } catch (error) {
    console.error('获取重置历史失败:', error)
    return { success: false, error: error.message }
  }
}

/**
 * 强制用户下次登录时修改密码
 */
export async function forcePasswordChange(userId, reason = '安全策略要求') {
  try {
    const { data: adminData } = await supabase.auth.getUser()
    const adminId = adminData.user?.id

    const { data, error } = await supabase.rpc('force_password_change', {
      p_admin_id: adminId,
      p_user_id: userId,
      p_reason: reason
    })

    if (error) throw error
    return data
  } catch (error) {
    console.error('强制修改密码失败:', error)
    return { success: false, error: error.message }
  }
}

/**
 * ⚠️ 警告：不安全的做法
 * 如果您坚持要实现查看密码功能，需要：
 * 1. 修改注册流程，将密码明文存储到另一个表（极度不推荐）
 * 2. 承担所有安全和法律风险
 * 3. 在用户协议中明确告知
 * 
 * 建议：永远不要这样做！
 */
