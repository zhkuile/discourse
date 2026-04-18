---
title: Windows 11 Development Setup Guide
short_title: Windows Setup
id: windows-setup
---

# Windows 11 上运行 Discourse 开发环境

本文档提供在 Windows 11 上运行 Discourse 项目的完整指南。

## 方案一：使用 Dev Container（推荐）⭐

这是最简单、最可靠的方式，Discourse 官方推荐。

### 前置要求

1. **安装 Docker Desktop for Windows**
   - 下载地址：https://www.docker.com/products/docker-desktop/
   - 安装后启动 Docker Desktop
   - 确保 WSL 2 后端已启用（Docker Desktop 设置中）

2. **安装 VS Code**
   - 下载地址：https://code.visualstudio.com/
   
3. **安装 Dev Containers 扩展**
   - 在 VS Code 中搜索并安装 "Dev Containers" 扩展
   - 或访问：https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

### 启动步骤

1. **打开项目**
   ```bash
   cd C:\Users\Administrator\Desktop\kundun\code\discourse
   code .
   ```

2. **在容器中重新打开**
   - VS Code 会检测到 `.devcontainer/devcontainer.json`
   - 点击右下角弹出的提示 "Reopen in Container"
   - 或按 `F1`，输入 "Dev Containers: Reopen in Container"

3. **等待容器构建**
   - 首次启动会下载 Docker 镜像（约 2-3 GB）
   - 安装依赖包（约 5-10 分钟）
   - 完成后会自动运行 `.devcontainer/scripts/start.rb`

4. **访问论坛**
   - 打开浏览器访问：http://localhost:4200
   - 或访问：http://localhost:3000（Rails 服务器）

### 端口说明

Dev Container 会自动转发以下端口：

- `4200` - Ember CLI 开发服务器（前端）
- `3000` - Rails 服务器（后端 API）
- `9292` - Unicorn 服务器
- `8025` - MailHog（邮件测试工具）
- `9229` - Chrome 远程调试

### 常用命令

在 VS Code 终端中（已在容器内）：

```bash
# 启动开发服务器
pnpm dev

# 或分别启动
bin/rails server              # 启动 Rails 后端
bin/ember-cli server          # 启动 Ember 前端

# 运行测试
bundle exec rspec             # Ruby 测试
pnpm test                     # JavaScript 测试

# 数据库操作
bundle exec rake db:migrate   # 运行迁移
bundle exec rake db:seed      # 填充种子数据

# 创建管理员账号
bundle exec rake admin:create
```

### 优点

✅ 环境隔离，不污染本地系统  
✅ 配置完整，开箱即用  
✅ 团队环境一致  
✅ 官方推荐和维护  

---

## 方案二：WSL 2 + 本地安装

如果你不想使用 Docker，可以在 WSL 2 中安装完整的开发环境。

### 前置要求

1. **启用 WSL 2**
   ```powershell
   # 以管理员身份运行 PowerShell
   wsl --install
   wsl --set-default-version 2
   ```

2. **安装 Ubuntu**
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

3. **进入 WSL**
   ```bash
   wsl
   ```

### 安装依赖

在 WSL Ubuntu 中执行：

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y git curl build-essential libssl-dev zlib1g-dev \
  libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev \
  libpq-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common

# 安装 PostgreSQL 13+
sudo apt install -y postgresql postgresql-contrib libpq-dev
sudo service postgresql start

# 安装 Redis 7+
sudo apt install -y redis-server
sudo service redis-server start

# 安装 Ruby 3.4+ (使用 rbenv)
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 3.4.1
rbenv global 3.4.1

# 安装 Node.js 20+ 和 pnpm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g pnpm@10

# 安装 ImageMagick
sudo apt install -y imagemagick libmagickwand-dev
```

### 配置数据库

```bash
# 创建 PostgreSQL 用户
sudo -u postgres createuser -s $USER
sudo -u postgres psql -c "ALTER USER $USER WITH PASSWORD 'password';"

# 创建数据库
createdb discourse_development
createdb discourse_test
```

### 克隆并设置项目

```bash
# 进入项目目录（从 Windows 访问）
cd /mnt/c/Users/Administrator/Desktop/kundun/code/discourse

# 或克隆到 WSL 文件系统（更快）
cd ~
git clone https://github.com/discourse/discourse.git
cd discourse

# 安装 Ruby 依赖
bundle install

# 安装 Node 依赖
pnpm install

# 配置数据库
cp config/database.yml.sample config/database.yml
# 编辑 config/database.yml，设置密码

# 运行数据库迁移
bundle exec rake db:create db:migrate

# 填充种子数据
bundle exec rake db:seed_fu

# 创建管理员账号
bundle exec rake admin:create
```

### 启动开发服务器

```bash
# 方式一：使用 pnpm dev（同时启动前后端）
pnpm dev

# 方式二：分别启动（推荐，便于调试）
# 终端 1：启动 Rails
RAILS_ENV=development bin/rails server

# 终端 2：启动 Ember CLI
bin/ember-cli server --environment=development
```

### 访问论坛

- 前端：http://localhost:4200
- 后端 API：http://localhost:3000

### 优点

✅ 性能更好（原生 Linux）  
✅ 完全控制环境  
✅ 可以深度定制  

### 缺点

❌ 初始设置复杂  
❌ 需要手动管理依赖版本  
❌ 可能遇到兼容性问题  

---

## 方案三：Windows 原生安装（不推荐）

Discourse 官方不推荐在 Windows 上直接安装，因为：

- Ruby on Rails 在 Windows 上性能较差
- 很多 gem 包在 Windows 上有兼容性问题
- PostgreSQL 和 Redis 配置复杂
- 缺少官方支持

如果坚持使用，请参考：https://meta.discourse.org/t/75149

---

## 推荐方案总结

| 方案 | 难度 | 性能 | 推荐度 |
|------|------|------|--------|
| Dev Container | ⭐ 简单 | ⭐⭐⭐ 好 | ⭐⭐⭐⭐⭐ 强烈推荐 |
| WSL 2 | ⭐⭐⭐ 中等 | ⭐⭐⭐⭐ 很好 | ⭐⭐⭐⭐ 推荐 |
| Windows 原生 | ⭐⭐⭐⭐⭐ 困难 | ⭐⭐ 一般 | ⭐ 不推荐 |

**建议：优先使用 Dev Container 方案**

---

## 常见问题

### Q: Docker Desktop 启动失败？
A: 确保已启用 WSL 2 和虚拟化功能（在 BIOS 中）

### Q: 容器构建很慢？
A: 首次构建需要下载大量依赖，请耐心等待。可以配置 Docker 镜像加速。

### Q: 端口被占用？
A: 检查是否有其他服务占用 3000、4200 等端口，关闭或修改配置。

### Q: 如何重置开发环境？
A: 
```bash
# Dev Container 方式
# 在 VS Code 中：F1 -> "Dev Containers: Rebuild Container"

# WSL 方式
bundle exec rake db:drop db:create db:migrate db:seed_fu
```

### Q: 如何查看日志？
A:
```bash
# Rails 日志
tail -f log/development.log

# Sidekiq 日志
tail -f log/sidekiq.log
```

---

## 下一步

环境搭建完成后，请参考：

- [云顶论坛改造执行计划](./YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](./yunding-branding-plan.md)
- [信息架构方案](./yunding-information-architecture.md)
- [站点设置清单](./yunding-site-settings-checklist.md)
