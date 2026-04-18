---
title: Yunding Forum Execution Plan
short_title: Execution Plan
id: yunding-execution-plan
---

# 云顶论坛改造执行计划（结合项目实际）

本文档基于当前 Discourse 项目的实际代码结构，提供可直接执行的改造方案。

---

## 前置条件：启动开发环境

在开始改造前，请先按照 [Windows 11 开发环境设置指南](./WINDOWS-SETUP.md) 启动项目。

**推荐方式**：使用 Dev Container

```bash
# 1. 确保 Docker Desktop 已启动
# 2. 在 VS Code 中打开项目
# 3. 点击 "Reopen in Container"
# 4. 等待容器启动完成
# 5. 访问 http://localhost:4200
```

---

## 阶段一：基础品牌替换（1-2天）

### 1.1 准备品牌资产

创建品牌资产目录：

```bash
# 在项目根目录执行
mkdir -p public/images/yunding-branding
```

**需要准备的文件**：

| 文件名 | 尺寸 | 用途 | 保存路径 |
|--------|------|------|----------|
| `logo.png` | 200x50px | 主 Logo | `public/images/yunding-branding/` |
| `logo-small.png` | 36x36px | 小 Logo | `public/images/yunding-branding/` |
| `logo-dark.png` | 200x50px | 暗色 Logo | `public/images/yunding-branding/` |
| `logo-small-dark.png` | 36x36px | 暗色小 Logo | `public/images/yunding-branding/` |
| `favicon.ico` | 32x32px | 浏览器图标 | `public/images/` |
| `apple-touch-icon.png` | 180x180px | iOS 图标 | `public/images/` |
| `og-image.png` | 1200x630px | 分享图 | `public/images/yunding-branding/` |
| `email-logo.png` | 400x100px | 邮件 Logo | `public/images/yunding-branding/` |

### 1.2 通过管理后台配置站点信息

启动开发环境后，访问管理后台进行配置：

1. **创建管理员账号**

```bash
# 在容器内或 WSL 中执行
bundle exec rake admin:create
# 按提示输入邮箱、密码等信息
```

2. **访问管理后台**

- 访问：http://localhost:4200
- 登录管理员账号
- 进入：设置 → 基本设置

3. **修改基础信息**

| 设置项 | 建议值 | 路径 |
|--------|--------|------|
| `title` | `云顶论坛` | 设置 → 基本 |
| `site_description` | `面向大数据、人工智能、Web3 及延展话题的专业社区` | 设置 → 基本 |
| `short_site_description` | `聚焦技术、连接观点、分享实践` | 设置 → 基本 |
| `company_name` | `@ydstack` | 设置 → 法律 |
| `contact_email` | 你的官方邮箱 | 设置 → 基本 |
| `notification_email` | `noreply@yourdomain.com` | 设置 → 邮件 |

4. **上传品牌资产**

- 进入：自定义 → 主题 → 编辑
- 上传准备好的 Logo 和图标文件

### 1.3 修改默认语言

- 进入：设置 → 本地化
- 设置 `default_locale` 为 `zh_CN`
- 启用 `allow_user_locale`（允许用户切换语言）

**预期成果**：访问 http://localhost:4200 时看到"云顶论坛"品牌

---

## 阶段二：信息架构建设（2-3天）

### 2.1 创建分类体系

**方式一：通过管理后台创建**

1. 访问：管理后台 → 分类
2. 点击"新建分类"
3. 按照以下结构创建：

**官方区**：
- [ ] 社区公告（颜色：#3498db）
- [ ] 新手专区（颜色：#2ecc71）
- [ ] 云顶产品（颜色：#9b59b6）

**技术主区**：
- [ ] 大数据技术（颜色：#3498db）
- [ ] 人工智能（颜色：#9b59b6）
- [ ] Web3（颜色：#f39c12）

**延展区**：
- [ ] 人文（颜色：#e74c3c）
- [ ] 地理（颜色：#27ae60）
- [ ] 生活随谈（颜色：#95a5a6）

**方式二：通过 Rails Console 批量创建**

```bash
# 在容器内执行
bundle exec rails console
```

```ruby
# 在 Rails Console 中执行
categories = [
  { name: "社区公告", color: "3498db", text_color: "FFFFFF", description: "官方通知、系统变更、活动公告、社区规则" },
  { name: "新手专区", color: "2ecc71", text_color: "FFFFFF", description: "新手指引、论坛使用教程、发帖规范、常见问题" },
  { name: "云顶产品", color: "9b59b6", text_color: "FFFFFF", description: "产品介绍、发布动态、使用说明、产品讨论" },
  { name: "大数据技术", color: "3498db", text_color: "FFFFFF", description: "数据平台、数据仓库、实时计算、湖仓一体、数据治理、数据分析" },
  { name: "人工智能", color: "9b59b6", text_color: "FFFFFF", description: "大模型/LLM、AIGC、Agent、RAG/向量数据库、模型部署、AI工程实践" },
  { name: "Web3", color: "f39c12", text_color: "FFFFFF", description: "区块链基础设施、智能合约、链上数据、钱包与身份、DeFi/NFT、Web3安全" },
  { name: "人文", color: "e74c3c", text_color: "FFFFFF", description: "阅读与思考、历史与文化、社会议题、观点讨论" },
  { name: "地理", color: "27ae60", text_color: "FFFFFF", description: "地缘观察、城市与区域、旅行见闻、地图与空间认知" },
  { name: "生活随谈", color: "95a5a6", text_color: "FFFFFF", description: "随便说说、社区闲聊、工作与生活、轻松话题" }
]

categories.each do |cat|
  Category.create!(
    name: cat[:name],
    color: cat[:color],
    text_color: cat[:text_color],
    description: cat[:description],
    user_id: User.find_by(admin: true).id
  )
end
```

### 2.2 创建标签体系

**通过管理后台**：

1. 访问：管理后台 → 标签
2. 创建以下标签：

**内容类型标签**：
- 安装部署
- 资源分享
- 问题求助
- 功能建议
- 开发编程
- 使用分享
- 使用教程
- 请求帮助
- 新手指引
- 产品咨询
- 随便说说

**官方标签**：
- 版本更新
- 活动公告

**通过 Rails Console 批量创建**：

```ruby
tags = [
  "安装部署", "资源分享", "问题求助", "功能建议", "开发编程",
  "使用分享", "使用教程", "请求帮助", "新手指引", "产品咨询",
  "随便说说", "版本更新", "活动公告"
]

tags.each do |tag_name|
  Tag.create!(name: tag_name)
end
```

### 2.3 配置导航菜单

**文件位置**：需要通过主题组件实现

创建自定义主题组件：

```bash
# 在项目根目录
mkdir -p themes/yunding-theme
mkdir -p themes/yunding-theme/common
```

创建主题配置文件：

**文件**：`themes/yunding-theme/about.json`

```json
{
  "name": "云顶论坛主题",
  "about_url": "https://github.com/ydstack/discourse",
  "license_url": "https://github.com/ydstack/discourse/blob/main/LICENSE.txt",
  "component": false,
  "color_schemes": {},
  "modifiers": {},
  "learn_more": "https://meta.discourse.org/t/beginners-guide-to-using-discourse-themes/91966"
}
```

**文件**：`themes/yunding-theme/common/common.scss`

```scss
// 云顶论坛自定义样式
:root {
  --yunding-primary: #3498db;
  --yunding-secondary: #2ecc71;
  --yunding-accent: #f39c12;
}

// 自定义导航样式
.d-header {
  background: var(--yunding-primary);
}
```

**文件**：`themes/yunding-theme/common/header.html`

```html
<script type="text/discourse-plugin" version="0.8">
  api.decorateWidget('home-logo:after', helper => {
    return helper.h('div.yunding-tagline', '聚焦技术、连接观点、分享实践');
  });
</script>
```

---

## 阶段三：内容初始化（2-3天）

### 3.1 创建官方引导内容

**方式一：通过管理后台创建**

1. 访问论坛首页
2. 点击"新建主题"
3. 创建以下主题并置顶：

**主题列表**：

| 标题 | 分类 | 是否置顶 | 内容要点 |
|------|------|----------|----------|
| 欢迎来到云顶论坛 | 社区公告 | 是 | 介绍论坛、运营主体、社区方向 |
| 新手必读 | 新手专区 | 是 | 注册、登录、发帖、回复指南 |
| 论坛使用指南 | 新手专区 | 是 | 分类说明、标签使用、搜索技巧 |
| 发帖规范 | 新手专区 | 是 | 标题规范、内容格式、代码块使用 |
| 云顶产品导航 | 云顶产品 | 是 | 产品列表、文档链接、GitHub 链接 |

**方式二：通过 Rake 任务批量创建**

创建种子数据文件：

**文件**：`db/fixtures/999_yunding_initial_content.rb`

```ruby
# frozen_string_literal: true

# 云顶论坛初始内容

admin = User.find_by(admin: true)

# 创建欢迎主题
welcome_category = Category.find_by(name: "社区公告")
if welcome_category && !Topic.find_by(title: "欢迎来到云顶论坛")
  PostCreator.create!(
    admin,
    title: "欢迎来到云顶论坛",
    raw: <<~MD,
      # 欢迎来到云顶论坛 🎉

      云顶论坛是一个面向大数据、人工智能、Web3 及延展话题的专业技术社区。

      ## 关于我们

      - **运营主体**：@ydstack
      - **社区方向**：大数据、人工智能、Web3、人文、地理
      - **社区价值观**：专业、开放、协作、分享

      ## 核心板块

      ### 技术主区
      - 🗄️ **大数据技术**：数据平台、实时计算、湖仓一体
      - 🤖 **人工智能**：大模型、Agent、RAG、AIGC
      - ⛓️ **Web3**：区块链、智能合约、链上数据

      ### 延展社区
      - 📚 **人文**：阅读、历史、文化、社会议题
      - 🌍 **地理**：地缘观察、城市研究、旅行见闻
      - 💬 **生活随谈**：社区闲聊、工作生活

      ## 快速开始

      1. 阅读 [新手必读](#{Topic.find_by(title: "新手必读")&.url || "#"})
      2. 了解 [发帖规范](#{Topic.find_by(title: "发帖规范")&.url || "#"})
      3. 浏览感兴趣的分类
      4. 开始你的第一个主题

      期待你的参与！
    MD
    category: welcome_category.id,
    pinned_at: Time.zone.now
  )
end

# 创建新手必读
newbie_category = Category.find_by(name: "新手专区")
if newbie_category && !Topic.find_by(title: "新手必读")
  PostCreator.create!(
    admin,
    title: "新手必读",
    raw: <<~MD,
      # 新手必读 📖

      欢迎加入云顶论坛！本指南帮助你快速上手。

      ## 如何注册和登录

      1. 点击右上角"注册"按钮
      2. 填写邮箱和密码
      3. 验证邮箱
      4. 完善个人资料

      ## 如何发帖

      1. 选择合适的分类
      2. 填写清晰的标题
      3. 编写详细的内容
      4. 添加相关标签
      5. 点击"创建主题"

      ## 如何回复

      1. 阅读主题内容
      2. 点击"回复"按钮
      3. 编写你的回复
      4. 可以引用他人内容
      5. 点击"回复"发布

      ## 使用 Markdown

      论坛支持 Markdown 格式：

      ```markdown
      # 一级标题
      ## 二级标题

      **粗体** *斜体*

      - 列表项 1
      - 列表项 2

      [链接文字](https://example.com)

      \`\`\`python
      # 代码块
      print("Hello, Yunding!")
      \`\`\`
      ```

      ## 社区礼仪

      - ✅ 保持友善和尊重
      - ✅ 提供有价值的内容
      - ✅ 使用搜索避免重复
      - ❌ 禁止广告和垃圾信息
      - ❌ 禁止人身攻击

      有问题？请在本主题下回复！
    MD
    category: newbie_category.id,
    pinned_at: Time.zone.now
  )
end
```

运行种子数据：

```bash
bundle exec rake db:seed_fu
```

### 3.2 创建技术种子内容

为每个技术分类创建 3-5 个高质量话题。可以：

1. 手动通过管理后台创建
2. 邀请团队成员贡献
3. 从现有技术博客迁移内容

**建议主题**：

**大数据技术**：
- 数据湖仓架构实践分享
- Flink vs Spark Streaming 对比
- 数据治理最佳实践

**人工智能**：
- 大模型部署实战
- RAG 系统构建指南
- Agent 框架选型对比

**Web3**：
- 智能合约安全审计要点
- 链上数据分析入门
- DeFi 协议原理解析

---

## 阶段四：主题定制与深度品牌化（3-5天）

### 4.1 创建自定义主题

**目录结构**：

```
themes/yunding-theme/
├── about.json
├── common/
│   ├── common.scss
│   ├── header.html
│   └── footer.html
├── desktop/
│   └── desktop.scss
└── mobile/
    └── mobile.scss
```

### 4.2 自定义首页 Hero Banner

**文件**：`themes/yunding-theme/common/header.html`

```html
<script type="text/discourse-plugin" version="0.8">
  const { h } = require("virtual-dom");
  
  api.decorateWidget('before-header-panel', helper => {
    if (helper.attrs.currentPath === 'discovery.latest' || 
        helper.attrs.currentPath === 'discovery.categories') {
      return h('div.yunding-hero', [
        h('div.hero-content', [
          h('h1.hero-title', '云顶论坛'),
          h('p.hero-tagline', '聚焦大数据、人工智能、Web3 与延展议题的专业社区'),
          h('div.hero-buttons', [
            h('a.btn.btn-primary', { href: '/c/新手专区' }, '论坛指南'),
            h('a.btn.btn-secondary', { href: '/c/云顶产品' }, '开源产品'),
            h('a.btn.btn-tertiary', { href: '/latest' }, '最新讨论')
          ])
        ])
      ]);
    }
  });
</script>
```

**文件**：`themes/yunding-theme/common/common.scss`

```scss
.yunding-hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 60px 20px;
  text-align: center;
  margin-bottom: 30px;
  
  .hero-content {
    max-width: 800px;
    margin: 0 auto;
  }
  
  .hero-title {
    font-size: 48px;
    color: white;
    margin-bottom: 20px;
    font-weight: 700;
  }
  
  .hero-tagline {
    font-size: 20px;
    color: rgba(255, 255, 255, 0.9);
    margin-bottom: 30px;
  }
  
  .hero-buttons {
    display: flex;
    gap: 15px;
    justify-content: center;
    flex-wrap: wrap;
    
    .btn {
      padding: 12px 30px;
      border-radius: 6px;
      text-decoration: none;
      font-weight: 600;
      transition: all 0.3s;
      
      &.btn-primary {
        background: white;
        color: #667eea;
        
        &:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }
      }
      
      &.btn-secondary {
        background: rgba(255, 255, 255, 0.2);
        color: white;
        border: 2px solid white;
        
        &:hover {
          background: rgba(255, 255, 255, 0.3);
        }
      }
      
      &.btn-tertiary {
        background: transparent;
        color: white;
        border: 2px solid rgba(255, 255, 255, 0.5);
        
        &:hover {
          border-color: white;
        }
      }
    }
  }
}

// 响应式设计
@media (max-width: 768px) {
  .yunding-hero {
    padding: 40px 15px;
    
    .hero-title {
      font-size: 32px;
    }
    
    .hero-tagline {
      font-size: 16px;
    }
    
    .hero-buttons {
      flex-direction: column;
      
      .btn {
        width: 100%;
      }
    }
  }
}
```

### 4.3 激活自定义主题

1. 访问：管理后台 → 自定义 → 主题
2. 点击"安装"
3. 选择"从目录"
4. 选择 `themes/yunding-theme`
5. 点击"设为默认主题"

### 4.4 去 Discourse 化处理

**修改 About 页面**：

**文件**：`app/views/about/index.html.erb`

找到并修改相关内容，或通过管理后台：

1. 访问：管理后台 → 自定义 → 文本内容
2. 搜索 "about"
3. 修改相关文本为云顶论坛的介绍

**修改页脚**：

**文件**：`themes/yunding-theme/common/footer.html`

```html
<script type="text/discourse-plugin" version="0.8">
  api.decorateWidget('footer:after', helper => {
    return helper.h('div.yunding-footer', [
      helper.h('p', '© 2025 云顶论坛 | 由 @ydstack 运营'),
      helper.h('div.footer-links', [
        helper.h('a', { href: '/about' }, '关于我们'),
        helper.h('span', ' | '),
        helper.h('a', { href: '/privacy' }, '隐私政策'),
        helper.h('span', ' | '),
        helper.h('a', { href: '/tos' }, '使用条款'),
        helper.h('span', ' | '),
        helper.h('a', { href: 'mailto:contact@yourdomain.com' }, '联系我们')
      ])
    ]);
  });
</script>
```

---

## 阶段五：测试与优化（1-2天）

### 5.1 功能测试清单

```bash
# 运行测试套件
bundle exec rspec
pnpm test
```

**手动测试**：

- [ ] 用户注册流程
- [ ] 登录/登出
- [ ] 发帖/回复
- [ ] 标签使用
- [ ] 分类浏览
- [ ] 搜索功能
- [ ] 通知系统
- [ ] 移动端体验
- [ ] 暗色模式

### 5.2 品牌一致性检查

**检查清单**：

- [ ] 首页显示云顶论坛品牌
- [ ] Logo 正确显示
- [ ] 导航栏品牌化
- [ ] 页脚信息正确
- [ ] About 页面已更新
- [ ] 邮件模板已定制
- [ ] 社交分享卡片正确
- [ ] 移动端品牌一致

### 5.3 性能优化

```bash
# 预编译资产
bundle exec rake assets:precompile

# 检查资产大小
du -sh public/assets/*

# 优化图片
# 使用 ImageOptim 或类似工具压缩图片
```

---

## 部署到生产环境

### 使用 Docker 部署（推荐）

参考官方文档：https://github.com/discourse/discourse_docker

```bash
# 克隆 discourse_docker
git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse

# 运行设置脚本
./discourse-setup

# 按提示输入：
# - 域名
# - 邮件配置
# - Let's Encrypt 邮箱
```

### 自定义配置

**文件**：`/var/discourse/containers/app.yml`

添加自定义主题和插件：

```yaml
hooks:
  after_code:
    - exec:
        cd: $home
        cmd:
          - git clone https://github.com/ydstack/yunding-theme.git plugins/yunding-theme
```

---

## 常见问题

### Q: 如何备份数据？

```bash
# 在容器内执行
bundle exec rake backup:create
```

### Q: 如何恢复数据？

```bash
bundle exec rake backup:restore FILE=/path/to/backup.tar.gz
```

### Q: 如何更新 Discourse？

```bash
cd /var/discourse
./launcher rebuild app
```

### Q: 如何查看日志？

```bash
# 开发环境
tail -f log/development.log

# 生产环境
./launcher logs app
```

---

## 总结

本执行计划提供了从开发环境搭建到生产部署的完整流程。关键步骤：

1. ✅ 使用 Dev Container 快速启动开发环境
2. ✅ 通过管理后台配置基础品牌信息
3. ✅ 创建分类和标签体系
4. ✅ 填充初始内容
5. ✅ 自定义主题实现深度品牌化
6. ✅ 测试和优化
7. ✅ 部署到生产环境

**下一步**：

- 持续产出高质量内容
- 建立社区运营机制
- 优化用户体验
- 推广云顶论坛品牌
