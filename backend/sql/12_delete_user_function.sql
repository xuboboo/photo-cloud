-- ============================================
-- 删除用户功能（超级管理员专用）
-- ============================================

-- 1. 创建删除用户的函数
-- ============================================

CREATE OR REPLACE FUNCTION delete_user_completely(target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
  files_deleted integer;
  shares_deleted integer;
  folders_deleted integer;
  logs_deleted integer;
BEGIN
  -- 检查调用者是否是超级管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role != 'super_admin' THEN
    RAISE EXCEPTION '只有超级管理员才能删除用户';
  END IF;
  
  -- 防止删除自己
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION '不能删除自己的账户';
  END IF;
  
  -- 防止删除其他超级管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = target_user_id;
  
  IF current_user_role = 'super_admin' THEN
    RAISE EXCEPTION '不能删除超级管理员账户';
  END IF;
  
  -- 1. 删除用户的文件夹
  DELETE FROM folders WHERE user_id = target_user_id;
  GET DIAGNOSTICS folders_deleted = ROW_COUNT;
  
  -- 2. 删除用户的文件记录
  DELETE FROM files WHERE user_id = target_user_id;
  GET DIAGNOSTICS files_deleted = ROW_COUNT;
  
  -- 3. 删除用户的分享记录
  DELETE FROM file_shares WHERE user_id = target_user_id;
  GET DIAGNOSTICS shares_deleted = ROW_COUNT;
  
  -- 4. 删除用户的活动日志
  DELETE FROM activity_logs WHERE user_id = target_user_id;
  GET DIAGNOSTICS logs_deleted = ROW_COUNT;
  
  -- 5. 删除用户配置
  DELETE FROM user_profiles WHERE id = target_user_id;
  
  -- 6. 删除认证用户（这会通过 CASCADE 自动删除相关记录）
  DELETE FROM auth.users WHERE id = target_user_id;
  
  -- 返回删除统计
  RETURN jsonb_build_object(
    'success', true,
    'message', '用户已完全删除',
    'statistics', jsonb_build_object(
      'files_deleted', files_deleted,
      'shares_deleted', shares_deleted,
      'folders_deleted', folders_deleted,
      'logs_deleted', logs_deleted
    )
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- 2. 授予执行权限
-- ============================================

GRANT EXECUTE ON FUNCTION delete_user_completely TO authenticated;

-- 3. 创建用于清理存储文件的辅助函数
-- ============================================

-- 获取用户的所有文件路径
CREATE OR REPLACE FUNCTION get_user_file_paths(target_user_id uuid)
RETURNS TABLE(file_path text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_role text;
BEGIN
  -- 检查调用者是否是管理员
  SELECT role INTO current_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF current_user_role IS NULL OR current_user_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION '只有管理员才能访问此功能';
  END IF;
  
  RETURN QUERY
  SELECT path
  FROM files
  WHERE user_id = target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_user_file_paths TO authenticated;

-- ============================================
-- 使用说明
-- ============================================

-- 1. 在前端调用此函数删除用户：
--    const { data, error } = await supabase.rpc('delete_user_completely', { target_user_id: userId })

-- 2. 在删除用户前，先获取文件路径并删除 Storage 中的文件：
--    const { data: filePaths } = await supabase.rpc('get_user_file_paths', { target_user_id: userId })

-- ============================================
-- 测试和验证
-- ============================================

-- 查看函数是否创建成功
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('delete_user_completely', 'get_user_file_paths');
