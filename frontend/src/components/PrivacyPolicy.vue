<template>
  <div class="policy-dialog-overlay" v-if="show" @click="handleClose">
    <div class="policy-dialog" @click.stop>
      <div class="policy-header">
        <h2>{{ title }}</h2>
        <button class="close-btn" @click="handleClose">✕</button>
      </div>
      
      <div class="policy-content">
        <div v-if="type === 'privacy'">
          <h3>隐私政策</h3>
          <p><strong>生效日期：</strong>2025年11月23日</p>
          
          <h4>1. 信息收集</h4>
          <p>我们收集以下信息：</p>
          <ul>
            <li>账户信息：邮箱地址、用户名</li>
            <li>上传内容：您上传的文件和图片</li>
            <li>使用数据：访问日志、IP地址、操作记录</li>
            <li>设备信息：浏览器类型、操作系统</li>
          </ul>

          <h4>2. 信息使用</h4>
          <p>我们使用收集的信息用于：</p>
          <ul>
            <li>提供和维护服务</li>
            <li>改进用户体验</li>
            <li>防止欺诈和滥用</li>
            <li>遵守法律法规</li>
          </ul>

          <h4>3. 信息保护</h4>
          <p>我们采取以下措施保护您的信息：</p>
          <ul>
            <li>数据加密传输（HTTPS）</li>
            <li>行级安全策略（RLS）</li>
            <li>定期安全审计</li>
            <li>访问权限控制</li>
          </ul>

          <h4>4. 信息共享</h4>
          <p>我们不会出售、交易或转让您的个人信息给第三方，除非：</p>
          <ul>
            <li>获得您的明确同意</li>
            <li>法律法规要求</li>
            <li>保护我们的权利和安全</li>
          </ul>

          <h4>5. Cookie使用</h4>
          <p>我们使用Cookie来：</p>
          <ul>
            <li>维持登录状态</li>
            <li>记住用户偏好</li>
            <li>分析网站流量</li>
          </ul>

          <h4>6. 数据删除</h4>
          <p>您有权要求删除您的账户和所有相关数据。请联系：<a href="mailto:news@tournews.top">news@tournews.top</a></p>

          <h4>7. 政策更新</h4>
          <p>我们可能会不时更新本隐私政策。重大更改会通过邮件或网站公告通知您。</p>

          <h4>8. 联系我们</h4>
          <p>如有疑问，请联系：<a href="mailto:news@tournews.top">news@tournews.top</a></p>
        </div>

        <div v-else-if="type === 'terms'">
          <h3>服务条款</h3>
          <p><strong>生效日期：</strong>2025年11月23日</p>
          
          <h4>1. 服务说明</h4>
          <p>Photo Cloud（以下简称"本服务"）是一个云存储和照片管理平台。使用本服务即表示您同意遵守以下条款。</p>

          <h4>2. 用户责任</h4>
          <p>作为用户，您同意：</p>
          <ul>
            <li>提供真实、准确的注册信息</li>
            <li>保护账户安全，不与他人共享</li>
            <li>不上传违法、有害、侵权的内容</li>
            <li>不滥用服务或进行恶意行为</li>
            <li>遵守所有适用的法律法规</li>
          </ul>

          <h4>3. 禁止行为</h4>
          <p>以下行为严格禁止：</p>
          <ul>
            <li>上传病毒、恶意软件</li>
            <li>侵犯他人版权、商标、隐私</li>
            <li>传播色情、暴力、仇恨内容</li>
            <li>发送垃圾邮件或广告</li>
            <li>尝试破解、攻击系统</li>
            <li>使用自动化工具批量注册</li>
          </ul>

          <h4>4. 内容所有权</h4>
          <ul>
            <li>您保留上传内容的所有权</li>
            <li>您授予我们存储、处理、展示内容的权限</li>
            <li>您对上传内容的合法性负责</li>
          </ul>

          <h4>5. 存储配额</h4>
          <ul>
            <li>免费账户默认1GB存储空间</li>
            <li>达到配额后需要升级或删除文件</li>
            <li>我们保留调整配额的权利</li>
          </ul>

          <h4>6. 服务变更与终止</h4>
          <ul>
            <li>我们可能随时修改、暂停或终止服务</li>
            <li>违反条款的账户将被暂停或删除</li>
            <li>服务终止前会提前通知</li>
          </ul>

          <h4>7. 免责声明</h4>
          <p><strong>重要：</strong></p>
          <ul>
            <li>服务"按现状"提供，不提供任何明示或暗示的保证</li>
            <li>我们不保证服务不中断、无错误、安全</li>
            <li>我们不对数据丢失、业务中断、利润损失负责</li>
            <li>您使用本服务的风险由您自行承担</li>
          </ul>

          <h4>8. 责任限制</h4>
          <p>在法律允许的最大范围内：</p>
          <ul>
            <li>开发者、运营者不对任何直接、间接、附带、特殊、惩罚性损害负责</li>
            <li>最大责任限额为您支付的服务费用</li>
            <li>对于第三方内容、链接、服务不承担责任</li>
          </ul>

          <h4>9. 赔偿</h4>
          <p>您同意赔偿并使开发者、运营者免受因以下原因产生的任何索赔、损失、责任：</p>
          <ul>
            <li>您违反本条款</li>
            <li>您上传的内容侵权</li>
            <li>您违反法律法规</li>
          </ul>

          <h4>10. 争议解决</h4>
          <ul>
            <li>本条款受中华人民共和国法律管辖</li>
            <li>争议应通过友好协商解决</li>
            <li>协商不成，提交有管辖权的法院诉讼</li>
          </ul>

          <h4>11. 联系方式</h4>
          <p>联系邮箱：<a href="mailto:news@tournews.top">news@tournews.top</a></p>

          <h4>12. 生效与修改</h4>
          <p>本条款自您勾选同意之日起生效。我们保留随时修改条款的权利，修改后的条款将在网站公布。</p>
        </div>
      </div>
      
      <div class="policy-footer">
        <button class="btn-secondary" @click="handleClose">关闭</button>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  show: Boolean,
  type: {
    type: String,
    default: 'privacy' // 'privacy' or 'terms'
  }
})

const emit = defineEmits(['update:show'])

const title = props.type === 'privacy' ? '隐私政策' : '服务条款'

function handleClose() {
  emit('update:show', false)
}
</script>

<style scoped>
.policy-dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
}

.policy-dialog {
  background: white;
  border-radius: 12px;
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.policy-header {
  padding: 20px 24px;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.policy-header h2 {
  margin: 0;
  font-size: 24px;
  color: #1f2937;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: #9ca3af;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #f3f4f6;
  color: #374151;
}

.policy-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  color: #374151;
  line-height: 1.6;
}

.policy-content h3 {
  margin: 0 0 16px 0;
  font-size: 20px;
  color: #1f2937;
}

.policy-content h4 {
  margin: 24px 0 12px 0;
  font-size: 16px;
  color: #1f2937;
  font-weight: 600;
}

.policy-content p {
  margin: 12px 0;
  font-size: 14px;
}

.policy-content ul {
  margin: 12px 0;
  padding-left: 24px;
}

.policy-content li {
  margin: 8px 0;
  font-size: 14px;
}

.policy-content a {
  color: #667eea;
  text-decoration: none;
}

.policy-content a:hover {
  text-decoration: underline;
}

.policy-content strong {
  color: #1f2937;
  font-weight: 600;
}

.policy-footer {
  padding: 16px 24px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
}

.btn-secondary {
  padding: 10px 24px;
  background: #f3f4f6;
  color: #374151;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #e5e7eb;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .policy-dialog-overlay {
    padding: 0;
  }
  
  .policy-dialog {
    max-width: 100%;
    max-height: 100vh;
    border-radius: 0;
  }
  
  .policy-header h2 {
    font-size: 20px;
  }
  
  .policy-content {
    padding: 20px 16px;
  }
  
  .policy-content h3 {
    font-size: 18px;
  }
  
  .policy-content h4 {
    font-size: 15px;
  }
  
  .policy-content p,
  .policy-content li {
    font-size: 13px;
  }
}
</style>
