# 云顶论坛部署方案

## 🎯 快速选择

### 生产环境部署（推荐）

**使用官方 discourse_docker 方案**：

```bash
# 1. 下载部署脚本
wget https://raw.githubusercontent.com/yourusername/discourse/prod/scripts/deploy-official.sh

# 2. 运行脚本
sudo bash deploy-official.sh forum.yourdomain.com admin@yourdomain.com

# 3. 编辑配置文件
sudo nano /var/discourse/containers/app.yml

# 4. 启动应用
cd /var/discourse
sudo ./launcher bootstrap app
sudo ./launcher start app
```

**详细文档**：[docs/PRODUCTION-DEPLOY.md](docs/PRODUCTION-DEPLOY.md)

---

### 开发/测试环境部署

**使用本项目提供的 Docker 方案**：

```bash
# 1. 克隆代码
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum

# 2. 配置环境变量
cp .env.example .env
nano .env

# 3. 启动服务
docker compose up -d postgres redis
sleep 10
docker compose up -d app

# 4. 初始化数据库
docker compose exec app bash
# 在容器内执行：
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed_fu
bundle exec rake admin:create
```

**详细文档**：[docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)

---

## 📊 方案对比

| 特性 | 官方方案 | 本项目方案 |
|------|----------|------------|
| 稳定性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 易用性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 灵活性 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 代码热更新 | ❌ | ✅ |
| 官方支持 | ✅ | ❌ |
| 适合场景 | 生产环境 | 开发/测试 |

---

## 📚 文档导航

### 部署相关
- [生产环境部署指南](docs/PRODUCTION-DEPLOY.md) - **推荐阅读**
- [完整部署指南](docs/DEPLOYMENT-GUIDE.md)
- [快速参考手册](docs/QUICK-REFERENCE.md)
- [部署方案总结](docs/DEPLOYMENT-SUMMARY.md)

### 云顶论坛改造
- [改造执行计划](docs/YUNDING-EXECUTION-PLAN.md)
- [品牌改造方案](docs/yunding-branding-plan.md)
- [信息架构方案](docs/yunding-information-architecture.md)
- [站点设置清单](docs/yunding-site-settings-checklist.md)

---

## 🚀 快速开始

### 生产环境（推荐）

```bash
# 一键部署
sudo bash scripts/deploy-official.sh forum.yourdomain.com admin@yourdomain.com
```

### 开发环境

```bash
# 启动开发环境
docker compose up -d
```

---

## 📞 获取帮助

- [Discourse 官方文档](https://meta.discourse.org)
- [Discourse 安装指南](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md)
- [discourse_docker 项目](https://github.com/discourse/discourse_docker)

---

## ✅ 推荐流程

1. **生产环境**：使用官方 discourse_docker 方案
2. **配置品牌**：通过管理后台修改站点设置
3. **创建内容**：创建分类、标签、欢迎主题
4. **安装插件**：添加需要的功能插件
5. **定期更新**：使用 `./launcher rebuild app` 更新

---

**开始部署吧！** 🎉
