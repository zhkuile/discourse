# 云顶论坛 - 快速部署指南

## 🚀 快速开始（5 分钟部署）

### 1. 克隆代码

```bash
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum
```

### 2. 配置环境变量

```bash
cp .env.example .env
nano .env  # 修改必要配置
```

**必须修改的配置**：
- `POSTGRES_PASSWORD` - 数据库密码
- `DISCOURSE_HOSTNAME` - 论坛域名
- `SMTP_*` - 邮件配置
- `SECRET_KEY_BASE` - 密钥（使用 `openssl rand -hex 64` 生成）

### 3. 一键部署

```bash
chmod +x deploy.sh
./deploy.sh deploy
```

### 4. 访问论坛

- HTTP: http://your-server-ip:3000
- HTTPS: https://forum.yourdomain.com

---

## 📦 目录结构

```
yunding-forum/
├── docker/
│   ├── Dockerfile          # 生产环境镜像
│   ├── entrypoint.sh       # 容器入口脚本
│   └── nginx.conf          # Nginx 配置
├── data/
│   ├── uploads/            # 用户上传文件
│   ├── backups/            # 数据库备份
│   └── logs/               # 应用日志
├── docker-compose.yml      # Docker Compose 配置
├── deploy.sh               # 部署脚本
├── .env.example            # 环境变量模板
└── docs/
    ├── DEPLOYMENT-GUIDE.md # 详细部署文档
    ├── WINDOWS-SETUP.md    # Windows 开发环境
    └── YUNDING-EXECUTION-PLAN.md # 改造执行计划
```

---

## 🔄 更新部署

当有新功能开发完成后：

```bash
# 在服务器上执行
./deploy.sh deploy
```

脚本会自动：
1. 拉取 `prod` 分支最新代码
2. 构建新的 Docker 镜像
3. 重启所有服务
4. 清理旧镜像

---

## 🛠️ 常用命令

```bash
# 查看服务状态
./deploy.sh status

# 查看日志
./deploy.sh logs

# 重启服务
./deploy.sh restart

# 创建备份
./deploy.sh backup
```

---

## 📚 详细文档

- [完整部署指南](docs/DEPLOYMENT-GUIDE.md)
- [云顶论坛改造计划](docs/YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](docs/yunding-branding-plan.md)
- [信息架构方案](docs/yunding-information-architecture.md)

---

## 🔧 技术栈

- **后端**: Ruby on Rails 8.0
- **前端**: Ember.js
- **数据库**: PostgreSQL 15
- **缓存**: Redis 7
- **容器**: Docker + Docker Compose
- **反向代理**: Nginx

---

## 📞 支持

如有问题，请查看 [故障排查](docs/DEPLOYMENT-GUIDE.md#十故障排查) 章节。
