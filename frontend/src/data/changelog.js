/**
 * 更新日志数据
 * 用于展示网站的活跃度和持续更新
 */

export const changelog = [
  {
    version: '2.0.0',
    date: '2025-11-23',
    type: 'major',
    title: 'International Support & SEO Optimization',
    titleZh: '国际化支持与 SEO 优化',
    changes: [
      {
        type: 'feature',
        description: 'Added support for 7 languages (Chinese, English, Japanese, Korean, Spanish, French, German)',
        descriptionZh: '支持 7 种语言（中文、英文、日语、韩语、西班牙语、法语、德语）'
      },
      {
        type: 'feature',
        description: 'Implemented automatic language detection',
        descriptionZh: '实现自动语言检测'
      },
      {
        type: 'feature',
        description: 'Enhanced SEO with hreflang tags and structured data',
        descriptionZh: '使用 hreflang 标签和结构化数据增强 SEO'
      },
      {
        type: 'feature',
        description: 'Added multilingual sitemap.xml',
        descriptionZh: '添加多语言 sitemap.xml'
      },
      {
        type: 'improvement',
        description: 'Optimized Core Web Vitals for better performance',
        descriptionZh: '优化 Core Web Vitals 以获得更好的性能'
      }
    ]
  },
  {
    version: '1.5.0',
    date: '2025-11-20',
    type: 'minor',
    title: 'Mobile Optimization',
    titleZh: '移动端优化',
    changes: [
      {
        type: 'fix',
        description: 'Fixed scroll position issue on mobile devices',
        descriptionZh: '修复移动设备上的滚动位置问题'
      },
      {
        type: 'improvement',
        description: 'Improved touch gestures and interactions',
        descriptionZh: '改进触摸手势和交互'
      },
      {
        type: 'improvement',
        description: 'Optimized layout for smaller screens',
        descriptionZh: '针对小屏幕优化布局'
      }
    ]
  },
  {
    version: '1.4.0',
    date: '2025-11-18',
    type: 'minor',
    title: 'Security Enhancements',
    titleZh: '安全增强',
    changes: [
      {
        type: 'security',
        description: 'Added email verification to prevent duplicate registrations',
        descriptionZh: '添加邮箱验证以防止重复注册'
      },
      {
        type: 'security',
        description: 'Implemented rate limiting for API requests',
        descriptionZh: '为 API 请求实现速率限制'
      },
      {
        type: 'feature',
        description: 'Added activity logs for administrators',
        descriptionZh: '为管理员添加活动日志'
      }
    ]
  },
  {
    version: '1.3.0',
    date: '2025-11-15',
    type: 'minor',
    title: 'File Sharing Updates',
    titleZh: '文件分享更新',
    changes: [
      {
        type: 'feature',
        description: 'Added password protection for share links',
        descriptionZh: '为分享链接添加密码保护'
      },
      {
        type: 'feature',
        description: 'Implemented download limit for shared files',
        descriptionZh: '为共享文件实现下载限制'
      },
      {
        type: 'improvement',
        description: 'Improved share link UI and UX',
        descriptionZh: '改进分享链接的 UI 和 UX'
      }
    ]
  },
  {
    version: '1.2.0',
    date: '2025-11-10',
    type: 'minor',
    title: 'Markdown Editor Enhancement',
    titleZh: 'Markdown 编辑器增强',
    changes: [
      {
        type: 'feature',
        description: 'Added real-time preview for Markdown files',
        descriptionZh: '为 Markdown 文件添加实时预览'
      },
      {
        type: 'feature',
        description: 'Implemented syntax highlighting',
        descriptionZh: '实现语法高亮'
      },
      {
        type: 'improvement',
        description: 'Enhanced editor performance',
        descriptionZh: '增强编辑器性能'
      }
    ]
  },
  {
    version: '1.1.0',
    date: '2025-11-05',
    type: 'minor',
    title: 'Admin Features',
    titleZh: '管理员功能',
    changes: [
      {
        type: 'feature',
        description: 'Added user management dashboard',
        descriptionZh: '添加用户管理仪表板'
      },
      {
        type: 'feature',
        description: 'Implemented storage quota management',
        descriptionZh: '实现存储配额管理'
      },
      {
        type: 'feature',
        description: 'Added system statistics and analytics',
        descriptionZh: '添加系统统计和分析'
      }
    ]
  },
  {
    version: '1.0.0',
    date: '2025-11-01',
    type: 'major',
    title: 'Initial Release',
    titleZh: '首次发布',
    changes: [
      {
        type: 'feature',
        description: 'Core file upload and management system',
        descriptionZh: '核心文件上传和管理系统'
      },
      {
        type: 'feature',
        description: 'User authentication and authorization',
        descriptionZh: '用户认证和授权'
      },
      {
        type: 'feature',
        description: 'Image preview and Markdown support',
        descriptionZh: '图片预览和 Markdown 支持'
      },
      {
        type: 'feature',
        description: 'Secure cloud storage with encryption',
        descriptionZh: '加密的安全云存储'
      }
    ]
  }
]

/**
 * 获取最新版本
 */
export function getLatestVersion() {
  return changelog[0]
}

/**
 * 根据类型获取更新
 */
export function getChangesByType(type) {
  return changelog.filter(change => change.type === type)
}

/**
 * 获取特定版本
 */
export function getVersionChanges(version) {
  return changelog.find(change => change.version === version)
}
