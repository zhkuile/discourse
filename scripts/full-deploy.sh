#!/bin/bash

# 云顶论坛完整部署脚本
# 包含：环境检查、代码更新、镜像构建、服务启动、SSL配置、监控安装、数据库初始化

set -e

echo "🚀 Yunding Forum Full Deployment Script"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --skip-ssl           Skip SSL certificate setup
  --skip-monitoring    Skip monitoring setup
  --skip-db-init       Skip database initialization
  --domain DOMAIN      Set domain for SSL certificate
  --help               Show this help message

Examples:
  $0                              # Full deployment with all features
  $0 --skip-ssl --skip-monitoring # Deploy without SSL and monitoring
  $0 --domain forum.example.com   # Deploy with SSL for specific domain

EOF
    exit 0
}

# 解析参数
SKIP_SSL=false
SKIP_MONITORING=false
SKIP_DB_INIT=false
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --skip-db-init)
            SKIP_DB_INIT=true
            shift
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --help)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# 步骤 1: 环境检查
print_step "Step 1/7: Checking environment..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed."
    print_info "Install Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed."
    exit 1
fi

# 检查 Git
if ! command -v git &> /dev/null; then
    print_error "Git is not installed."
    print_info "Install Git: sudo apt install -y git"
    exit 1
fi

print_info "✅ Environment check passed!"

# 步骤 2: 配置环境变量
print_step "Step 2/7: Configuring environment variables..."

if [ ! -f .env ]; then
    print_warn ".env file not found. Creating from template..."
    cp .env.example .env
    
    # 生成密钥
    SECRET_KEY=$(openssl rand -hex 64)
    sed -i "s/your_secret_key_base_here/$SECRET_KEY/" .env
    
    print_warn "Please edit .env file with your configuration:"
    print_warn "  nano .env"
    print_warn ""
    print_warn "Required configurations:"
    print_warn "  - POSTGRES_PASSWORD"
    print_warn "  - DISCOURSE_HOSTNAME"
    print_warn "  - SMTP_* (email settings)"
    print_warn "  - ADMIN_EMAIL and ADMIN_PASSWORD"
    print_warn ""
    print_warn "After configuration, run this script again."
    exit 1
fi

print_info "✅ Environment variables configured!"

# 步骤 3: 拉取最新代码
print_step "Step 3/7: Pulling latest code from prod branch..."

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    print_warn "You have uncommitted changes. Stashing..."
    git stash
fi

# 拉取最新代码
git pull origin prod

print_info "✅ Code updated!"

# 步骤 4: 构建和启动服务
print_step "Step 4/7: Building and starting services..."

# 创建数据目录
mkdir -p data/uploads data/backups data/logs docker/ssl

# 停止旧容器
docker compose down

# 构建新镜像
print_info "Building Docker image (this may take a few minutes)..."
docker compose build --no-cache

# 启动服务
print_info "Starting services..."
docker compose up -d

# 等待服务就绪
print_info "Waiting for services to be ready..."
sleep 10

# 检查服务状态
if ! docker compose ps | grep -q "Up"; then
    print_error "Services failed to start. Check logs:"
    docker compose logs
    exit 1
fi

print_info "✅ Services started!"

# 步骤 5: 配置 SSL 证书
if [ "$SKIP_SSL" = false ]; then
    print_step "Step 5/7: Setting up SSL certificate..."
    
    if [ -z "$DOMAIN" ]; then
        # 从 .env 读取域名
        DOMAIN=$(grep DISCOURSE_HOSTNAME .env | cut -d '=' -f2)
    fi
    
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost" ]; then
        print_info "Setting up SSL for domain: $DOMAIN"
        
        # 检查是否已有证书
        if [ -f "docker/ssl/cert.pem" ] && [ -f "docker/ssl/key.pem" ]; then
            print_warn "SSL certificate already exists. Skipping..."
        else
            # 运行 SSL 配置脚本
            if [ -f "scripts/setup-ssl.sh" ]; then
                chmod +x scripts/setup-ssl.sh
                sudo scripts/setup-ssl.sh $DOMAIN || print_warn "SSL setup failed. You can configure it manually later."
            else
                print_warn "SSL setup script not found. Skipping..."
            fi
        fi
    else
        print_warn "No domain configured. Skipping SSL setup."
    fi
    
    print_info "✅ SSL configuration completed!"
else
    print_step "Step 5/7: Skipping SSL setup (--skip-ssl)"
fi

# 步骤 6: 安装监控
if [ "$SKIP_MONITORING" = false ]; then
    print_step "Step 6/7: Setting up monitoring..."
    
    if [ -f "scripts/setup-monitoring.sh" ]; then
        chmod +x scripts/setup-monitoring.sh
        ./scripts/setup-monitoring.sh
        
        # 启动监控服务
        if [ -f "scripts/start-monitoring.sh" ]; then
            chmod +x scripts/start-monitoring.sh
            ./scripts/start-monitoring.sh
        fi
    else
        print_warn "Monitoring setup script not found. Skipping..."
    fi
    
    print_info "✅ Monitoring setup completed!"
else
    print_step "Step 6/7: Skipping monitoring setup (--skip-monitoring)"
fi

# 步骤 7: 初始化数据库
if [ "$SKIP_DB_INIT" = false ]; then
    print_step "Step 7/7: Initializing database..."
    
    if [ -f "scripts/init-database.sh" ]; then
        chmod +x scripts/init-database.sh
        ./scripts/init-database.sh
    else
        print_warn "Database initialization script not found. Skipping..."
    fi
    
    print_info "✅ Database initialization completed!"
else
    print_step "Step 7/7: Skipping database initialization (--skip-db-init)"
fi

# 清理旧镜像
print_info "Cleaning up old Docker images..."
docker image prune -f

# 显示部署信息
echo ""
echo "========================================"
echo "🎉 Deployment Completed Successfully!"
echo "========================================"
echo ""
echo "📋 Deployment Summary:"
echo "  - Branch: prod"
echo "  - Environment: production"
echo "  - Domain: ${DOMAIN:-localhost}"
echo ""

# 从 .env 读取端口
APP_PORT=$(grep APP_PORT .env | cut -d '=' -f2)
APP_PORT=${APP_PORT:-3000}

echo "🌐 Access Points:"
echo "  - Forum: http://localhost:$APP_PORT"
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost" ]; then
    echo "  - Forum (HTTPS): https://$DOMAIN"
fi
echo ""

if [ "$SKIP_MONITORING" = false ]; then
    echo "📊 Monitoring:"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Grafana: http://localhost:3001"
    echo "  - cAdvisor: http://localhost:8081"
    echo ""
fi

echo "📚 Useful Commands:"
echo "  - View logs: ./deploy.sh logs"
echo "  - Restart: ./deploy.sh restart"
echo "  - Stop: ./deploy.sh stop"
echo "  - Status: ./deploy.sh status"
echo "  - Backup: ./deploy.sh backup"
echo ""

echo "📖 Documentation:"
echo "  - Deployment Guide: docs/DEPLOYMENT-GUIDE.md"
echo "  - Execution Plan: docs/YUNDING-EXECUTION-PLAN.md"
echo ""

echo "✨ Happy forum building!"
