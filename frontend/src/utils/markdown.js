import MarkdownIt from 'markdown-it'

// 创建 Markdown 渲染器实例
const md = new MarkdownIt({
  html: true,        // 允许 HTML 标签
  linkify: true,     // 自动转换 URL 为链接
  typographer: true, // 启用智能引号和其他排版替换
  breaks: true       // 转换换行符为 <br>
})

/**
 * 渲染 Markdown 文本为 HTML
 */
export function renderMarkdown(text) {
  if (!text) return ''
  
  try {
    return md.render(text)
  } catch (error) {
    console.error('Markdown render error:', error)
    return '<p>渲染错误</p>'
  }
}

/**
 * 渲染 Markdown 内联文本
 */
export function renderMarkdownInline(text) {
  if (!text) return ''
  
  try {
    return md.renderInline(text)
  } catch (error) {
    console.error('Markdown inline render error:', error)
    return text
  }
}

export default md
