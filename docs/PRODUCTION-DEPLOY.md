# 云顶论坛生产环境部署方案（推荐）

## ⚠️ 重要说明

Discourse 官方推荐使用 [discourse_docker](https://github.com/discourse/discourse_docker) 进行生产环境部署。

本文档提供两种部署方式：
1. **方式一：官方推荐方式**（discourse_docker）- 最稳定、最简单
2. **方式二：自定义 Docker 方式**（本项目提供的方案）- 更灵活、支持代码热更新

---

## 方式一：使用 discourse_docker（推荐）⭐

### 优点
- ✅ 官方推荐和维护
- ✅ 配置简单，开箱即用
- ✅ 自动更新和备份
- ✅ 稳定性最高

### 缺点
- ❌ 不支持代码热更新
- ❌ 自定义修改需要重新构建镜像

### 部署步骤

#### 1. 准备服务器

```bash
# Ubuntu 22.04 服务器
# 至少 2GB RAM
# 至少 20GB 磁盘空间
```

#### 2. 安装 Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 3. 克隆 discourse_docker

```bash
sudo mkdir -p /var/discourse
sudo chown $USER:$USER /var/discourse
git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse
```

#### 4. 配置应用

```bash
# 复制配置模板
cp samples/standalone.yml containers/app.yml

# 编辑配置
nano containers/app.yml
```

**必须修改的配置**：

```yaml
# 域名
DISCOURSE_HOSTNAME: 'forum.yourdomain.com'

# 管理员邮箱
DISCOURSE_DEVELOPER_EMAILS: 'admin@yourdomain.com'

# SMTP 邮件配置
DISCOURSE_SMTP_ADDRESS: smtp.yourmail.com
DISCOURSE_SMTP_PORT: 587
DISCOURSE_SMTP_USER_NAME: your_email@yourmail.com
DISCOURSE_SMTP_PASSWORD: your_smtp_password

# Let's Encrypt 邮箱
LETSENCRYPT_ACCOUNT_EMAIL: admin@yourdomain.com
```

#### 5. 启动应用

```bash
# 启动引导（首次启动，会自动配置）
./launcher bootstrap app

# 启动应用
./launcher start app
```

#### 6. 访问论坛

访问：https://forum.yourdomain.com

#### 7. 更新应用

```bash
cd /var/discourse
./launcher rebuild app
```

### 自定义云顶论坛

#### 方式 A：通过管理后台配置

1. 访问管理后台
2. 修改站点设置
3. 上传 Logo 和图标
4. 创建分类和标签

#### 方式 B：通过插件方式

1. 创建自定义插件
2. 在 `containers/app.yml` 中添加：

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/ydstack/yunding-theme.git
```

3. 重建应用：

```bash
./launcher rebuild app
```

---

## 方式二：使用本项目提供的 Docker 方案

### 优点
- ✅ 支持代码热更新
- ✅ 更灵活的自定义
- ✅ 适合开发环境

### 缺点
- ❌ 需要手动维护
- ❌ 稳定性不如官方方案

### 部署步骤

#### 1. 安装 Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. 克隆代码

```bash
git clone -b prod https://github.com/yourusername/discourse.git yunding-forum
cd yunding-forum
```

#### 3. 配置环境变量

```bash
cp .env.example .env
nano .env
```

#### 4. 启动服务

```bash
# 创建数据目录
mkdir -p data/uploads data/backups data/logs

# 启动数据库和 Redis
docker compose up -d postgres redis

# 等待数据库就绪
sleep 10

# 启动应用
docker compose up -d app

# 查看日志
docker compose logs -f app
```

#### 5. 初始化数据库

```bash
# 进入容器
docker compose exec app bash

# 在容器内执行
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed_fu
bundle exec rake admin:create
```

#### 6. 访问论坛

访问：http://localhost:3000

---

## 推荐方案对比

| 特性 | discourse_docker | 本项目方案 |
|------|------------------|------------|
| 稳定性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 易用性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 灵活性 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 代码热更新 | ❌ | ✅ |
| 官方支持 | ✅ | ❌ |
| 适合场景 | 生产环境 | 开发/测试环境 |

---

## 建议

### 生产环境
**强烈推荐使用 discourse_docker**，因为：
- 官方维护和支持
- 稳定性最高
- 自动更新和备份
- 社区支持

### 开发/测试环境
可以使用本项目提供的方案，因为：
- 支持代码热更新
- 更灵活的自定义
- 便于调试

---

## 快速决策

**如果你想要：**
- ✅ 最稳定的生产环境 → 使用 **discourse_docker**
- ✅ 快速上线 → 使用 **discourse_docker**
- ✅ 深度自定义 → 使用 **discourse_docker + 插件**
- ✅ 开发测试 → 使用 **本项目方案**

---

## 下一步

1. 选择合适的部署方式
2. 按照对应文档进行部署
3. 配置云顶论坛品牌（参考 `docs/yunding-branding-plan.md`）
4. 创建分类和标签（参考 `docs/yunding-information-architecture.md`）

---

## 相关文档

- [discourse_docker 官方文档](https://github.com/discourse/discourse_docker)
- [Discourse 安装指南](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md)
- [云顶论坛品牌改造](./yunding-branding-plan.md)
- [信息架构方案](./yunding-information-architecture.md)
