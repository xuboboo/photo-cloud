-- =====================================================
-- 批量验证管理员邮箱
-- 将所有管理员和超级管理员的邮箱标记为已验证
-- =====================================================

-- 1. 验证所有管理员邮箱
UPDATE auth.users
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, now())
WHERE id IN (
  SELECT id 
  FROM user_profiles 
  WHERE role IN ('admin', 'super_admin')
)
AND email_confirmed_at IS NULL;

-- 2. 显示验证结果
DO $$
DECLARE
  v_verified_count int;
  v_admin_count int;
  v_already_verified int;
BEGIN
  -- 统计总管理员数
  SELECT COUNT(*) INTO v_admin_count
  FROM user_profiles
  WHERE role IN ('admin', 'super_admin');
  
  -- 统计已验证的管理员数
  SELECT COUNT(*) INTO v_already_verified
  FROM user_profiles up
  JOIN auth.users u ON u.id = up.id
  WHERE up.role IN ('admin', 'super_admin')
    AND u.email_confirmed_at IS NOT NULL;
  
  -- 显示结果
  RAISE NOTICE '===== 管理员邮箱验证完成 =====';
  RAISE NOTICE '总管理员数: %', v_admin_count;
  RAISE NOTICE '已验证数: %', v_already_verified;
  RAISE NOTICE '验证率: %%%', ROUND((v_already_verified::numeric / NULLIF(v_admin_count, 0)::numeric * 100), 2);
  RAISE NOTICE '';
  RAISE NOTICE '✅ 所有管理员邮箱已设置为已验证状态';
  RAISE NOTICE '============================';
END $$;

-- 3. 显示详细的管理员列表
SELECT 
  u.email as "邮箱",
  up.role as "角色",
  CASE 
    WHEN u.email_confirmed_at IS NOT NULL THEN '✓ 已验证'
    ELSE '✗ 未验证'
  END as "邮箱状态",
  u.email_confirmed_at as "验证时间",
  up.created_at as "注册时间"
FROM user_profiles up
JOIN auth.users u ON u.id = up.id
WHERE up.role IN ('admin', 'super_admin')
ORDER BY up.role DESC, u.email;

-- 4. 创建自动验证管理员邮箱的触发器（可选）
CREATE OR REPLACE FUNCTION auto_verify_admin_email()
RETURNS TRIGGER AS $$
BEGIN
  -- 当用户角色变为管理员时，自动验证邮箱
  IF NEW.role IN ('admin', 'super_admin') AND 
     OLD.role NOT IN ('admin', 'super_admin') THEN
    
    UPDATE auth.users
    SET 
      email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = NEW.id;
    
    RAISE NOTICE '自动验证管理员邮箱: %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_auto_verify_admin_email ON user_profiles;
CREATE TRIGGER trigger_auto_verify_admin_email
  AFTER UPDATE OF role ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION auto_verify_admin_email();

COMMENT ON TRIGGER trigger_auto_verify_admin_email ON user_profiles IS '自动验证管理员邮箱';

-- 完成提示
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '===== 配置完成 =====';
  RAISE NOTICE '1. ✓ 所有现有管理员邮箱已验证';
  RAISE NOTICE '2. ✓ 已创建自动验证触发器';
  RAISE NOTICE '3. ✓ 新晋升的管理员将自动验证邮箱';
  RAISE NOTICE '===================';
END $$;
