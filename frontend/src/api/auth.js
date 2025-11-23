import { supabase } from './supabase'

/**
 * 用户登录
 */
export async function login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ 
    email, 
    password 
  })
  
  if (error) throw error
  return data
}

/**
 * 用户注册
 */
export async function register(email, password) {
  const { data, error } = await supabase.auth.signUp({ 
    email, 
    password 
  })
  
  if (error) throw error
  return data
}

/**
 * 获取当前用户
 */
export async function getUser() {
  const { data, error } = await supabase.auth.getUser()
  
  if (error) throw error
  return data
}

/**
 * 用户登出
 */
export async function logout() {
  const { error } = await supabase.auth.signOut()
  
  if (error) throw error
}

/**
 * 监听认证状态变化
 */
export function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange(callback)
}
