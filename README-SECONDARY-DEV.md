# 云顶论坛 - 二次开发部署方案

## 🎯 适用场景

本方案专为需要对 Discourse 进行**二次开发**的场景设计：

- ✅ 修改 Discourse 核心代码
- ✅ 添加自定义功能
- ✅ 深度定制界面
- ✅ 代码热更新
- ✅ 频繁迭代开发

---

## 🚀 快速开始

### 1. 安装 Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. 克隆代码

```bash
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum
```

### 3. 配置环境变量

```bash
cp .env.example .env
nano .env  # 修改必要配置
```

### 4. 一键部署

```bash
chmod +x deploy-dev.sh
./deploy-dev.sh init
./deploy-dev.sh init-db
```

### 5. 访问论坛

访问：http://localhost:3000

---

## 🔄 更新流程

### 开发环境

```bash
# 开发新功能
git checkout prod
git pull origin prod
# ... 编写代码 ...
git add .
git commit -m "Add new feature"
git push origin prod
```

### 生产环境

```bash
# 一键更新
./deploy-dev.sh update
```

---

## 🛠️ 常用命令

```bash
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

# 查看状态
./deploy-dev.sh status
```

---

## 📁 核心文件

| 文件 | 说明 |
|------|------|
| `docker/Dockerfile` | Docker 镜像定义 |
| `docker/entrypoint.sh` | 容器启动脚本 |
| `docker-compose.yml` | 服务编排配置 |
| `deploy-dev.sh` | 部署脚本 |
| `.env` | 环境变量配置 |

---

## 📚 详细文档

- [二次开发部署指南](docs/SECONDARY-DEVELOPMENT.md) - **推荐阅读**
- [云顶论坛改造计划](docs/YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](docs/yunding-branding-plan.md)
- [信息架构方案](docs/yunding-information-architecture.md)

---

## ✅ 核心优势

✅ **支持代码热更新** - Git pull + 重新构建 + 重启  
✅ **完整开发环境** - 包含所有开发工具  
✅ **数据持久化** - 所有数据挂载到宿主机  
✅ **快速迭代** - 分钟级更新部署  
✅ **灵活定制** - 可修改任何代码  

---

## 🎯 与官方方案对比

| 特性 | 本方案 | 官方 discourse_docker |
|------|--------|----------------------|
| 代码热更新 | ✅ | ❌ |
| 二次开发 | ✅ | ❌ |
| 灵活定制 | ✅ | ⭐⭐⭐ |
| 稳定性 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 易用性 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 官方支持 | ❌ | ✅ |

---

## 🆘 常见问题

### 1. 镜像构建失败

```bash
# 清理缓存重新构建
docker system prune -a
docker compose build --no-cache
```

### 2. 数据库连接失败

```bash
# 检查数据库状态
docker compose ps postgres
docker compose logs postgres
```

### 3. 权限问题

```bash
# 修复权限
sudo chown -R $USER:$USER data
chmod -R 755 data
```

---

## 📞 获取帮助

- [详细部署文档](docs/SECONDARY-DEVELOPMENT.md)
- [Discourse 官方文档](https://meta.discourse.org)
- [故障排查指南](docs/SECONDARY-DEVELOPMENT.md#常见问题)

---

**开始你的二次开发之旅！** 🚀
