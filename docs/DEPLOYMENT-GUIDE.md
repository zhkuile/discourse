---
title: Yunding Forum Deployment Guide
short_title: Deployment Guide
id: deployment-guide
---

# 云顶论坛生产环境部署指南

本文档提供在 Ubuntu 22.04 上部署云顶论坛的完整步骤。

---

## 前置要求

### 服务器要求

- **操作系统**：Ubuntu 22.04 LTS
- **内存**：至少 2GB RAM（推荐 4GB+）
- **磁盘**：至少 20GB 可用空间
- **网络**：公网 IP 和域名

### 软件要求

- Docker
- Docker Compose
- Git

---

## 一、安装 Docker 和 Docker Compose

### 1. 安装 Docker

```bash
# 更新软件包索引
sudo apt update

# 安装依赖
sudo apt install -y ca-certificates curl gnupg lsb-release

# 添加 Docker 官方 GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到 docker 组（可选，避免每次使用 sudo）
sudo usermod -aG docker $USER
newgrp docker
```

### 2. 验证安装

```bash
docker --version
docker compose version
```

---

## 二、准备项目代码

### 1. 克隆代码

```bash
# 创建项目目录
mkdir -p /opt/yunding-forum
cd /opt/yunding-forum

# 克隆代码（使用 prod 分支）
git clone -b prod git@github.com:zhkuile/discourse.git  .
```

### 2. 配置环境变量

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

### 3. 生成密钥

```bash
# 生成 SECRET_KEY_BASE
openssl rand -hex 64
```

---

## 三、部署应用

### 方式一：使用部署脚本（推荐）

```bash
# 给脚本添加执行权限
chmod +x deploy.sh

# 执行完整部署
./deploy.sh deploy
```

### 方式二：手动部署

```bash
# 1. 创建数据目录
mkdir -p data/uploads data/backups data/logs docker/ssl

# 2. 构建镜像
docker compose build

# 3. 启动服务
docker compose up -d

# 4. 查看日志
docker compose logs -f app

# 5. 检查服务状态
docker compose ps
```

---

## 四、配置 SSL 证书（可选但推荐）

### 使用 Let's Encrypt 免费证书

```bash
# 安装 Certbot
sudo apt install -y certbot

# 获取证书（替换 yourdomain.com）
sudo certbot certonly --standalone -d forum.yourdomain.com

# 复制证书到项目目录
sudo cp /etc/letsencrypt/live/forum.yourdomain.com/fullchain.pem docker/ssl/cert.pem
sudo cp /etc/letsencrypt/live/forum.yourdomain.com/privkey.pem docker/ssl/key.pem

# 设置权限
sudo chown -R $USER:$USER docker/ssl
chmod 600 docker/ssl/key.pem

# 重启 Nginx
docker compose restart nginx
```

### 自动续期

```bash
# 添加定时任务
sudo crontab -e

# 添加以下行（每月 1 号凌晨 2 点续期）
0 2 1 * * certbot renew --quiet && cp /etc/letsencrypt/live/forum.yourdomain.com/fullchain.pem /opt/yunding-forum/docker/ssl/cert.pem && cp /etc/letsencrypt/live/forum.yourdomain.com/privkey.pem /opt/yunding-forum/docker/ssl/key.pem && cd /opt/yunding-forum && docker compose restart nginx
```

---

## 五、验证部署

### 1. 检查服务状态

```bash
# 查看容器状态
docker compose ps

# 应该看到以下容器运行中：
# - yunding-postgres
# - yunding-redis
# - yunding-app
# - yunding-sidekiq
# - yunding-nginx
```

### 2. 访问论坛

- HTTP: http://your-server-ip:3000
- HTTPS: https://forum.yourdomain.com

### 3. 登录管理员账号

使用 `.env` 中配置的管理员邮箱和密码登录。

---

## 六、日常运维

### 更新部署

当有新功能开发完成后，执行以下步骤：

```bash
# 进入项目目录
cd /opt/yunding-forum

# 执行部署脚本（自动拉取代码、重建镜像、重启服务）
./deploy.sh deploy
```

**部署脚本会自动执行**：
1. 拉取 `prod` 分支最新代码
2. 构建新的 Docker 镜像
3. 停止旧容器
4. 启动新容器
5. 清理旧镜像

### 常用命令

```bash
# 查看服务状态
./deploy.sh status

# 查看日志
./deploy.sh logs

# 重启服务
./deploy.sh restart

# 停止服务
./deploy.sh stop

# 启动服务
./deploy.sh start

# 创建备份
./deploy.sh backup
```

### 数据备份

```bash
# 手动备份
docker compose exec app bundle exec rake backup:create

# 备份文件位置
ls -lh data/backups/
```

### 数据恢复

```bash
# 恢复备份
docker compose exec app bundle exec rake backup:restore FILE=/var/www/discourse/public/backups/backup-file.tar.gz
```

---

## 七、数据目录说明

### 挂载的数据目录

| 目录 | 说明 | 挂载点 |
|------|------|--------|
| `data/uploads` | 用户上传文件 | `/var/www/discourse/public/uploads` |
| `data/backups` | 数据库备份 | `/var/www/discourse/public/backups` |
| `data/logs` | 应用日志 | `/var/www/discourse/log` |
| `docker/ssl` | SSL 证书 | `/etc/nginx/ssl` |

### 数据库数据

PostgreSQL 和 Redis 数据存储在 Docker Volume 中：

```bash
# 查看 volume
docker volume ls

# 查看 volume 详情
docker volume inspect yunding-forum_postgres_data
docker volume inspect yunding-forum_redis_data
```

---

## 八、性能优化

### 1. 调整 Docker 资源限制

编辑 `docker-compose.yml`，添加资源限制：

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 2. 优化 PostgreSQL

创建 `docker/postgresql.conf`：

```ini
shared_buffers = 256MB
effective_cache_size = 1GB
max_connections = 200
```

### 3. 优化 Redis

在 `docker-compose.yml` 中添加 Redis 配置：

```yaml
redis:
  command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
```

---

## 九、监控和日志

### 查看应用日志

```bash
# 实时查看日志
docker compose logs -f app

# 查看最近 100 行日志
docker compose logs --tail=100 app

# 查看特定时间段的日志
docker compose logs --since=2h app
```

### 查看容器资源使用

```bash
# 实时监控
docker stats

# 查看特定容器
docker stats yunding-app yunding-sidekiq
```

---

## 十、故障排查

### 常见问题

#### 1. 容器无法启动

```bash
# 查看容器日志
docker compose logs app

# 检查配置文件
docker compose config

# 重新构建镜像
docker compose build --no-cache
```

#### 2. 数据库连接失败

```bash
# 检查数据库容器状态
docker compose ps postgres

# 检查数据库日志
docker compose logs postgres

# 手动连接数据库测试
docker compose exec postgres psql -U discourse -d discourse
```

#### 3. 权限问题

```bash
# 修复数据目录权限
sudo chown -R $USER:$USER data
chmod -R 755 data
```

#### 4. 端口被占用

```bash
# 查看端口占用
sudo netstat -tulpn | grep :3000

# 修改 .env 中的端口配置
APP_PORT=3001
```

---

## 十一、安全建议

### 1. 防火墙配置

```bash
# 安装 UFW
sudo apt install -y ufw

# 允许必要端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# 启用防火墙
sudo ufw enable
```

### 2. 定期更新

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 更新 Docker 镜像
docker compose pull
docker compose up -d
```

### 3. 定期备份

```bash
# 添加定时备份任务
crontab -e

# 每天凌晨 3 点备份
0 3 * * * cd /opt/yunding-forum && docker compose exec -T app bundle exec rake backup:create
```

---

## 十二、扩容和高可用

### 水平扩展

```bash
# 扩展 Sidekiq 工作进程
docker compose up -d --scale sidekiq=3
```

### 负载均衡

使用 Nginx 或 HAProxy 进行负载均衡，将请求分发到多个应用实例。

---

## 总结

部署流程总结：

1. ✅ 安装 Docker 和 Docker Compose
2. ✅ 克隆代码（prod 分支）
3. ✅ 配置环境变量（.env）
4. ✅ 执行部署脚本（./deploy.sh deploy）
5. ✅ 配置 SSL 证书
6. ✅ 验证部署
7. ✅ 日常运维（更新、备份、监控）

**更新流程**：

```bash
# 开发完成后，推送到 prod 分支
git push origin prod

# 在服务器上执行
./deploy.sh deploy
```

就这么简单！🎉
