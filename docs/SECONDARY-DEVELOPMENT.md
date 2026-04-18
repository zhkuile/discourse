# 云顶论坛二次开发部署指南

## 🎯 适用场景

本文档适用于需要对 Discourse 进行**二次开发**的场景：

- ✅ 需要修改 Discourse 核心代码
- ✅ 需要添加自定义功能
- ✅ 需要深度定制界面
- ✅ 需要代码热更新
- ✅ 需要频繁迭代开发

---

## 📋 部署架构

```
┌─────────────────────────────────────────────────────────┐
│                    代码仓库 (Git)                         │
│                   prod 分支                               │
└────────────────────┬────────────────────────────────────┘
                     │ git pull
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Docker 镜像构建                              │
│         包含所有代码和依赖                                │
└────────────────────┬────────────────────────────────────┘
                     │ docker compose up
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  运行容器                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │   App    │  │ Sidekiq  │  │ Postgres │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│  ┌──────────┐                                           │
│  │  Redis   │                                           │
│  └──────────┘                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 快速部署

### 1. 准备服务器

**要求**：
- Ubuntu 22.04 LTS
- 至少 2GB RAM（推荐 4GB）
- 至少 20GB 磁盘空间
- 公网 IP 和域名

### 2. 安装 Docker

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh

# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker

# 验证安装
docker --version
docker compose version
```

### 3. 克隆代码

```bash
# 创建项目目录
mkdir -p /opt/yunding-forum
cd /opt/yunding-forum

# 克隆代码（prod 分支）
git clone -b prod https://github.com/yourusername/discourse.git .
```

### 4. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**必须修改的配置**：

```bash
# 数据库密码（必须修改！）
POSTGRES_PASSWORD=your_secure_password_here

# 论坛域名（必须修改！）
DISCOURSE_HOSTNAME=forum.yourdomain.com

# 邮件配置（必须配置！）
SMTP_ADDRESS=smtp.yourmail.com
SMTP_PORT=587
SMTP_USER=your_email@yourmail.com
SMTP_PASSWORD=your_smtp_password

# 管理员账号（首次启动时创建）
CREATE_ADMIN=true
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_admin_password

# 密钥（必须修改！）
# 生成方式: openssl rand -hex 64
SECRET_KEY_BASE=your_secret_key_base_here
```

### 5. 生成密钥

```bash
# 生成 SECRET_KEY_BASE
openssl rand -hex 64
```

### 6. 创建数据目录

```bash
# 创建数据目录
mkdir -p data/uploads data/backups data/logs

# 设置权限
chmod -R 755 data
```

### 7. 构建镜像

```bash
# 构建镜像（首次构建需要 10-15 分钟）
docker compose build
```

### 8. 启动服务

```bash
# 启动数据库和 Redis
docker compose up -d postgres redis

# 等待数据库就绪
sleep 10

# 启动应用
docker compose up -d app

# 查看日志
docker compose logs -f app
```

### 9. 初始化数据库

```bash
# 进入应用容器
docker compose exec app bash

# 在容器内执行以下命令：

# 创建数据库
bundle exec rake db:create

# 运行迁移
bundle exec rake db:migrate

# 填充种子数据
bundle exec rake db:seed_fu

# 创建管理员账号（如果 .env 中配置了）
# 或者手动创建：
bundle exec rake admin:create

# 退出容器
exit
```

### 10. 访问论坛

- 访问：http://your-server-ip:3000
- 使用管理员账号登录

---

## 🔄 更新部署流程

### 开发环境

```bash
# 1. 开发新功能
git checkout prod
git pull origin prod

# 2. 编写代码
# ... 修改文件 ...

# 3. 测试
bundle exec rspec
pnpm test

# 4. 提交代码
git add .
git commit -m "Add new feature"
git push origin prod
```

### 生产环境

```bash
# 1. 拉取最新代码
cd /opt/yunding-forum
git pull origin prod

# 2. 重新构建镜像
docker compose build

# 3. 重启服务
docker compose down
docker compose up -d

# 4. 查看日志
docker compose logs -f app
```

### 一键更新脚本

```bash
# 使用部署脚本
./deploy.sh deploy
```

---

## 🛠️ 开发调试

### 进入容器

```bash
# 进入应用容器
docker compose exec app bash

# 进入数据库容器
docker compose exec postgres bash

# 进入 Redis 容器
docker compose exec redis sh
```

### 查看日志

```bash
# 应用日志
docker compose logs -f app

# 数据库日志
docker compose logs -f postgres

# Sidekiq 日志
docker compose logs -f sidekiq

# 所有日志
docker compose logs -f
```

### 运行 Rails 命令

```bash
# Rails console
docker compose exec app bundle exec rails console

# 运行迁移
docker compose exec app bundle exec rake db:migrate

# 预编译资产
docker compose exec app bundle exec rake assets:precompile

# 创建管理员
docker compose exec app bundle exec rake admin:create
```

### 数据库操作

```bash
# 连接数据库
docker compose exec postgres psql -U discourse -d discourse

# 备份数据库
docker compose exec app bundle exec rake backup:create

# 恢复数据库
docker compose exec app bundle exec rake backup:restore FILE=/var/www/discourse/public/backups/backup.tar.gz
```

---

## 📁 目录结构

```
/opt/yunding-forum/
├── app/                    # 应用代码
│   ├── controllers/       # 控制器
│   ├── models/            # 模型
│   ├── views/             # 视图
│   └── ...
├── config/                # 配置文件
├── db/                    # 数据库文件
├── lib/                   # 库文件
├── plugins/               # 插件
├── frontend/              # 前端代码
├── docker/                # Docker 配置
│   ├── Dockerfile        # 镜像定义
│   └── entrypoint.sh     # 启动脚本
├── data/                  # 数据目录（持久化）
│   ├── uploads/          # 用户上传文件
│   ├── backups/          # 数据库备份
│   └── logs/             # 应用日志
├── docker-compose.yml     # 服务编排
├── deploy.sh              # 部署脚本
└── .env                   # 环境变量
```

---

## 🔧 常见问题

### 1. 镜像构建失败

**问题**：`cannot load such file -- debug/prelude`

**解决**：
```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建
docker compose build --no-cache
```

### 2. 数据库连接失败

**问题**：`PG::ConnectionBad`

**解决**：
```bash
# 检查数据库容器状态
docker compose ps postgres

# 查看数据库日志
docker compose logs postgres

# 重启数据库
docker compose restart postgres
```

### 3. 资产预编译失败

**问题**：资产预编译报错

**解决**：
```bash
# 进入容器手动预编译
docker compose exec app bash
bundle exec rake assets:precompile
```

### 4. 权限问题

**问题**：无法写入文件

**解决**：
```bash
# 修复数据目录权限
sudo chown -R $USER:$USER data
chmod -R 755 data
```

### 5. 端口被占用

**问题**：端口 3000 被占用

**解决**：
```bash
# 查看端口占用
sudo netstat -tulpn | grep :3000

# 修改 .env 中的端口
APP_PORT=3001
```

---

## 📊 性能优化

### 1. 调整 Docker 资源

编辑 `docker-compose.yml`：

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### 2. 优化 PostgreSQL

创建 `docker/postgresql.conf`：

```ini
shared_buffers = 256MB
effective_cache_size = 1GB
max_connections = 200
```

### 3. 优化 Redis

在 `docker-compose.yml` 中：

```yaml
redis:
  command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
```

---

## 🔐 安全建议

### 1. 修改默认密码

- 数据库密码
- 管理员密码
- SECRET_KEY_BASE

### 2. 配置防火墙

```bash
# 安装 UFW
sudo apt install -y ufw

# 允许必要端口
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 启用防火墙
sudo ufw enable
```

### 3. 定期备份

```bash
# 添加定时备份
crontab -e

# 每天凌晨 3 点备份
0 3 * * * cd /opt/yunding-forum && docker compose exec -T app bundle exec rake backup:create
```

---

## 📚 相关文档

- [云顶论坛改造计划](./YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](./yunding-branding-plan.md)
- [信息架构方案](./yunding-information-architecture.md)
- [站点设置清单](./yunding-site-settings-checklist.md)

---

## ✅ 部署检查清单

### 部署前

- [ ] 已安装 Docker 和 Docker Compose
- [ ] 已克隆代码（prod 分支）
- [ ] 已配置 .env 文件
- [ ] 已生成 SECRET_KEY_BASE
- [ ] 已配置邮件服务器
- [ ] 已设置域名解析

### 部署后

- [ ] 所有容器正常运行
- [ ] 可以访问论坛
- [ ] 管理员账号可以登录
- [ ] 数据库备份已创建
- [ ] 日志正常输出

---

**开始你的二次开发之旅！** 🚀

一键部署：
# 1. 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. 克隆代码
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum

# 3. 配置环境变量
cp .env.example .env
nano .env  # 修改必要配置

# 4. 一键部署
chmod +x deploy-dev.sh
./deploy-dev.sh init
./deploy-dev.sh init-db

# 5. 访问论坛
# http://localhost:3000


更新开发流程：
# 在开发环境
git checkout prod
git pull origin prod
# ... 编写代码 ...
git add .
git commit -m "Add new feature"
git push origin prod


# 在服务器上执行
./deploy-dev.sh update

常用命令

# 初始化部署
./deploy-dev.sh init

# 初始化数据库
./deploy-dev.sh init-db

# 更新部署
./deploy-dev.sh update

# 查看日志
./deploy-dev.sh logs

# 进入容器
./deploy-dev.sh bash

# Rails console
./deploy-dev.sh console

# 创建备份
./deploy-dev.sh backup

