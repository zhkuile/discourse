---
title: Project Architecture
short_title: Architecture
id: project-architecture
---

# 项目架构说明

## 1. 项目简介

Discourse 是一个面向社区讨论场景的开源平台，支持传统论坛、私信、实时聊天、通知、审核、搜索、主题定制和插件扩展等能力。它并不是一个单一用途的论坛程序，而是一个可扩展的社区操作系统：核心提供稳定的讨论能力，插件与主题机制负责承载不同业务场景。

从仓库结构来看，Discourse 采用典型的 Ruby on Rails 单体应用架构，但在工程上又通过插件、主题、后台任务、事件机制和独立的资源注入体系，将平台能力拆分得足够灵活，适合长期演进。

## 2. 架构目标

Discourse 的架构设计主要围绕以下目标：

- **高可扩展性**：通过插件和主题系统扩展功能，而不破坏核心代码。
- **高可维护性**：按 controller、model、service、job、serializer 分层组织代码。
- **高可用与可恢复性**：依赖 Redis、Sidekiq、备份与恢复工具保证系统稳定运行。
- **社区治理能力**：内建审核、权限、举报、风控、日志与管理后台。
- **多场景适配**：既支持长文本论坛，也支持短消息聊天、自动化流程、集成能力。

## 3. 总体技术栈

### 后端

- Ruby 3.4+
- Rails 8
- ActiveRecord
- Action Controller / View / Mailer
- Sidekiq
- Mini Scheduler

### 前端

- Ember.js
- Rails 负责 API 输出，前端负责交互与渲染
- 主题与插件可注入样式和脚本

### 数据与基础设施

- PostgreSQL：主业务数据存储
- Redis：缓存、会话、临时状态、队列相关数据
- S3 / 对象存储：上传文件、备份、媒体资源
- MessageBus：消息通知与实时事件传播

### 常用配套库

- OmniAuth：第三方登录
- Nokogiri / Loofah：HTML 解析与清洗
- FastImage / Image Optim：图片处理
- Onebox：外链预览
- Logster / Lograge：日志

## 4. 分层架构

### 4.1 表现层

表现层主要位于 `app/controllers`、`app/serializers`、`app/helpers` 与前端资源目录中。

职责包括：

- 接收 HTTP 请求
- 做参数校验与权限判断
- 调用领域模型或服务对象
- 将结果序列化为 JSON 或 HTML
- 为前端提供页面与接口数据

典型特征：

- 管理后台、站点页面、API、Webhook 都通过 controller 暴露
- serializer 用于统一控制 API 输出结构
- 复杂页面通常由前端 SPA 接管交互

### 4.2 领域层

领域层主要位于 `app/models` 与 `app/services`。

#### `app/models`

负责核心领域实体和业务状态，例如：

- 用户、群组、权限
- 主题、帖子、分类、标签
- 通知、收藏、点赞
- 审核对象、举报对象
- 上传、链接、邮件、站点设置

#### `app/services`

负责复杂业务流程编排，例如：

- 发帖与编辑流程
- 通知与消息生成
- 搜索索引更新
- 用户合并、迁移、清理
- 主题与站点设置相关逻辑

### 4.3 基础设施层

主要位于 `lib/`。

这一层提供更底层的通用能力：

- 权限框架 `Guardian`
- 插件机制 `Plugin`
- 事件机制 `DiscourseEvent`
- 中间件实现
- 站点设置校验与依赖图
- 邮件、上传、备份、Onebox、主题编译等基础能力

这层代码通常不直接面向某个业务页面，而是为整个系统提供通用服务。

### 4.4 异步处理层

主要位于 `app/jobs`。

职责包括：

- 邮件投递
- 通知聚合与发送
- 搜索索引与重建
- 定时清理与数据修复
- 上传处理与图片转换
- 外部集成同步

Discourse 将大量非实时任务放入后台异步执行，以保证主请求路径尽可能轻量。

## 5. 核心模块

### 5.1 用户与权限

用户体系是 Discourse 的基础。主要包括：

- 用户账户
- 用户偏好
- 组与组成员关系
- Trust Level 信任等级
- API Key 与 OAuth 登录
- 认证与授权

权限判断通常通过 `Guardian` 统一处理，避免权限逻辑散落在各个 controller 中。

### 5.2 内容系统

内容系统围绕以下实体组织：

- `Topic`：讨论主题
- `Post`：帖子正文
- `Category`：分类
- `Tag`：标签
- `Draft`：草稿
- `Bookmark`：收藏
- `Like`：点赞

这一层负责构建社区讨论的主数据模型。

### 5.3 通知与消息

通知系统覆盖：

- 站内通知
- 邮件通知
- 私信提醒
- 订阅通知
- 实时消息推送

它通常由模型、serializer、mailer 与 job 协同完成。

### 5.4 审核与治理

Discourse 内建完整的治理体系：

- 举报与审核队列
- 屏蔽词、邮件屏蔽、IP 屏蔽、URL 屏蔽
- Staff Action Log
- 风控与反垃圾机制
- 审核对象 `Reviewable`

这体现了 Discourse 对“社区运营可控性”的重视。

### 5.5 搜索系统

搜索相关对象和服务包括：

- 搜索日志
- 帖子/主题/标签索引
- 站点和插件自定义索引
- 定时重建索引任务

搜索是平台能力的重要组成部分，插件也可以参与注册搜索索引。

### 5.6 上传与媒体

系统支持：

- 图片上传
- 附件和备份
- 视频与音频引用
- 外链内容预览
- 上传安全校验

这部分与对象存储、图像优化、中间件和内容解析密切相关。

## 6. 插件架构

插件系统是 Discourse 最重要的扩展机制之一。

### 6.1 插件入口

每个插件通常以 `plugin.rb` 为入口，声明：

- 插件名称和元信息
- 启用条件
- 资源注册
- 路由扩展
- 初始化逻辑

### 6.2 插件能力

插件可以：

- 添加管理后台页面
- 注入样式与脚本
- 注册事件监听器
- 扩展 serializer 字段
- 扩展模型行为
- 添加后台任务
- 注册搜索索引
- 扩展上传使用判断

### 6.3 典型示例

#### `plugins/chat`

提供原生聊天能力，说明插件可以深度接入核心：

- 注册聊天相关资产
- 扩展用户、群组、通知、书签、审核等核心对象
- 注册搜索索引
- 注册 onebox 处理器
- 增加用户序列化字段

#### `plugins/automation`

提供自动化流程能力，说明插件可以接收系统事件并执行规则：

- 监听用户首次登录、加入/移出群组等事件
- 触发自动化脚本
- 提供后台管理入口
- 注册 API Key 作用域

## 7. 请求处理流程

### 7.1 页面请求流程

1. 浏览器发起请求
2. Rails 路由命中对应 controller
3. controller 进行参数校验与权限检查
4. 调用 model / service / query 对象获取数据
5. serializer 输出 API 响应
6. 前端 Ember 渲染页面
7. 如需实时更新，借助 MessageBus 或后台任务补充状态

### 7.2 发帖流程

1. 用户提交帖子内容
2. controller 接收请求
3. service 进行校验、清洗、风控与上传解析
4. 写入 `Topic` / `Post` / 相关关联表
5. 触发通知、索引、统计等异步任务
6. 前端更新 UI

### 7.3 后台任务流程

1. 业务逻辑将耗时操作封装成 job
2. job 进入 Sidekiq 队列或定时调度器
3. 后台 worker 执行任务
4. 结果回写数据库或缓存
5. 必要时触发事件或通知

## 8. 配置与启动机制

Discourse 的启动配置集中在 `config/application.rb` 和 `config/initializers/*`。

关键机制包括：

- `GlobalSetting` 负责全局配置加载
- 启动时决定是否加载插件
- 自定义 middleware 注入请求链路
- Redis 与 cache_store 在启动阶段绑定
- 多站点配置路径可被环境变量覆盖
- 插件在 `after_initialize` 阶段完成最终挂载

这套机制使得核心应用和插件在启动时能够形成统一运行时环境。

## 9. 数据流与依赖关系

### 9.1 典型依赖方向

- Controller 依赖 Service / Model
- Service 依赖 Model / Query / Helper
- Job 依赖 Service / Model
- Serializer 依赖 Model / Current User / Scope
- Plugin 可以依赖核心对象，并通过 patch 扩展其行为

### 9.2 数据流特点

- 主业务数据写入 PostgreSQL
- 临时与高频状态写入 Redis
- 任务结果通过 Sidekiq 异步推进
- 搜索和通知常常是“写后异步补全”
- 插件通过事件与扩展点参与同一数据流

## 10. 部署视角

从仓库结构可以看出，Discourse 适合以下部署模式：

- **Web 进程**：处理 HTTP 请求
- **Worker 进程**：处理 Sidekiq 队列
- **Scheduler 进程**：处理定时任务
- **数据库**：PostgreSQL
- **缓存/队列**：Redis
- **对象存储**：存储上传与备份
- **反向代理**：通常由 Nginx 等代理处理静态资源和压缩

## 11. 架构总结

Discourse 的核心架构可以概括为：

- **Rails 单体应用** 作为稳定核心
- **插件系统** 作为扩展主轴
- **后台任务系统** 承接异步与周期性工作
- **Redis + PostgreSQL** 形成核心数据支撑
- **Ember 前端** 提供现代化交互体验
- **主题与插件** 共同实现高度定制化

这套架构的优点是成熟、灵活、适合长期运营；代价是系统复杂度较高，需要对插件机制、后台任务、权限与数据流有较强理解。

## 12. 建议的后续文档

如果要继续完善项目文档，建议补充：

- `docs/modules.md`：核心模块拆解
- `docs/plugins.md`：插件开发与扩展点说明
- `docs/deployment.md`：部署与运维说明
- `docs/request-flow.md`：请求链路与异步流程
- `docs/data-model.md`：核心表结构与领域模型

