# 云顶论坛 - 快速参考手册

## 🚀 快速部署

### 首次部署

```bash
# 1. 克隆代码
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum

# 2. 配置环境变量
cp .env.example .env
nano .env  # 修改必要配置

# 3. 一键部署
chmod +x scripts/full-deploy.sh
./scripts/full-deploy.sh
```

### 更新部署

```bash
# 拉取最新代码并重新部署
./deploy.sh deploy
```

---

## 📁 目录结构

```
yunding-forum/
├── docker/                    # Docker 配置
│   ├── Dockerfile            # 生产环境镜像
│   ├── entrypoint.sh         # 容器入口脚本
│   ├── nginx.conf            # Nginx 配置
│   └── ssl/                  # SSL 证书目录
├── scripts/                   # 部署脚本
│   ├── full-deploy.sh        # 完整部署脚本
│   ├── setup-ssl.sh          # SSL 证书配置
│   ├── setup-monitoring.sh   # 监控配置
│   └── init-database.sh      # 数据库初始化
├── monitoring/                # 监控配置
│   ├── prometheus/           # Prometheus 配置
│   └── grafana/              # Grafana 配置
├── data/                      # 数据目录（持久化）
│   ├── uploads/              # 用户上传文件
│   ├── backups/              # 数据库备份
│   └── logs/                 # 应用日志
├── docker-compose.yml         # Docker Compose 配置
├── deploy.sh                  # 部署脚本
└── .env                       # 环境变量配置
```

---

## 🛠️ 常用命令

### 服务管理

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
```

### 数据库操作

```bash
# 初始化数据库
./scripts/init-database.sh

# 创建备份
./deploy.sh backup

# 恢复备份
docker compose exec app bundle exec rake backup:restore FILE=/var/www/discourse/public/backups/backup-file.tar.gz

# 进入数据库
docker compose exec postgres psql -U discourse -d discourse
```

### SSL 证书

```bash
# 配置 SSL 证书
sudo ./scripts/setup-ssl.sh forum.yourdomain.com

# 手动续期
sudo ./scripts/renew-ssl.sh forum.yourdomain.com
```

### 监控

```bash
# 启动监控
./scripts/start-monitoring.sh

# 停止监控
./scripts/stop-monitoring.sh
```

---

## 🌐 访问地址

### 应用服务

| 服务 | 地址 | 说明 |
|------|------|------|
| 论坛 | http://localhost:3000 | 主应用 |
| 论坛 (HTTPS) | https://forum.yourdomain.com | 生产环境 |

### 监控服务

| 服务 | 地址 | 默认账号 |
|------|------|----------|
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3001 | admin / admin |
| cAdvisor | http://localhost:8081 | - |

---

## ⚙️ 环境变量配置

### 必须配置

```bash
# 数据库
POSTGRES_PASSWORD=your_secure_password

# 论坛域名
DISCOURSE_HOSTNAME=forum.yourdomain.com

# 邮件配置
SMTP_ADDRESS=smtp.yourmail.com
SMTP_PORT=587
SMTP_USER=your_email@yourmail.com
SMTP_PASSWORD=your_smtp_password

# 管理员账号
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_admin_password

# 密钥
SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### 可选配置

```bash
# 应用端口
APP_PORT=3000

# 监控
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_grafana_password
```

---

## 🔧 故障排查

### 查看日志

```bash
# 应用日志
docker compose logs -f app

# 数据库日志
docker compose logs -f postgres

# Nginx 日志
docker compose logs -f nginx

# 所有服务日志
docker compose logs -f
```

### 重启服务

```bash
# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart app
docker compose restart sidekiq
docker compose restart nginx
```

### 进入容器

```bash
# 进入应用容器
docker compose exec app bash

# 进入数据库容器
docker compose exec postgres bash

# 进入 Redis 容器
docker compose exec redis sh
```

### 检查资源使用

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
df -h

# 查看数据目录大小
du -sh data/*
```

---

## 📊 性能优化

### Docker 资源限制

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

### PostgreSQL 优化

创建 `docker/postgresql.conf`：

```ini
shared_buffers = 256MB
effective_cache_size = 1GB
max_connections = 200
```

### Redis 优化

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
- Grafana 密码
- Redis 密码（如需要）

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
0 3 * * * cd /opt/yunding-forum && ./deploy.sh backup
```

### 4. 定期更新

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 更新 Docker 镜像
docker compose pull
docker compose up -d
```

---

## 📚 相关文档

- [完整部署指南](./DEPLOYMENT-GUIDE.md)
- [云顶论坛改造计划](./YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](./yunding-branding-plan.md)
- [信息架构方案](./yunding-information-architecture.md)
- [站点设置清单](./yunding-site-settings-checklist.md)

---

## 🆘 获取帮助

### 查看帮助

```bash
# 部署脚本帮助
./deploy.sh --help

# 完整部署脚本帮助
./scripts/full-deploy.sh --help
```

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   sudo netstat -tulpn | grep :3000
   
   # 修改 .env 中的端口
   APP_PORT=3001
   ```

2. **权限问题**
   ```bash
   # 修复数据目录权限
   sudo chown -R $USER:$USER data
   chmod -R 755 data
   ```

3. **数据库连接失败**
   ```bash
   # 检查数据库状态
   docker compose ps postgres
   
   # 查看数据库日志
   docker compose logs postgres
   ```

---

## ✅ 检查清单

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
- [ ] SSL 证书配置成功
- [ ] 监控服务正常运行
- [ ] 数据库备份已创建

---

**祝部署顺利！🎉**
