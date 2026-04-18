#!/bin/bash

# 云顶论坛完整初始化脚本
# 包含：构建镜像、启动服务、初始化数据库

set -e

echo "🚀 Yunding Forum Complete Initialization Script"
echo "================================================="

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

# 检查环境变量
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
    exit 1
fi

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 步骤 1: 停止现有容器
print_step "Step 1/8: Stopping existing containers..."
docker compose down

# 步骤 2: 创建数据目录
print_step "Step 2/8: Creating data directories..."
mkdir -p data/uploads data/backups data/logs
chmod -R 755 data

# 步骤 3: 构建镜像
print_step "Step 3/8: Building Docker image (this may take 10-15 minutes)..."
docker compose build

# 步骤 4: 启动数据库
print_step "Step 4/8: Starting database services..."
docker compose up -d postgres redis

print_info "Waiting for database to be ready..."
sleep 20

# 检查数据库是否就绪
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker exec yunding-postgres pg_isready -U ${POSTGRES_USER:-discourse} > /dev/null 2>&1; then
        print_info "✅ Database is ready!"
        break
    fi
    echo "Waiting for database... attempt $attempt/$max_attempts"
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Database failed to start. Check logs: docker logs yunding-postgres"
    exit 1
fi

# 步骤 5: 创建数据库
print_step "Step 5/8: Creating database..."
docker exec -it yunding-postgres psql -U ${POSTGRES_USER:-discourse} -d postgres -c "CREATE DATABASE ${POSTGRES_DB:-discourse};" || print_warn "Database may already exist, continuing..."

# 步骤 6: 启动应用
print_step "Step 6/8: Starting application..."
docker compose up -d app

print_info "Waiting for application to be ready..."
sleep 15

# 步骤 7: 初始化数据库
print_step "Step 7/8: Initializing database..."

print_info "Running migrations..."
docker compose exec -T app bundle exec rake db:migrate

print_info "Seeding database..."
docker compose exec -T app bundle exec rake db:seed_fu

# 步骤 8: 创建管理员账号
print_step "Step 8/8: Creating admin account..."

if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
    print_info "Creating admin account with email: $ADMIN_EMAIL"
    docker compose exec -T app bundle exec rake admin:create["$ADMIN_EMAIL","$ADMIN_PASSWORD"] <<EOF
y
EOF
    print_info "✅ Admin account created!"
else
    print_warn "Admin credentials not found in .env. Creating manually..."
    docker compose exec -it app bundle exec rake admin:create
fi

# 完成
echo ""
echo "========================================"
echo "🎉 Initialization Completed Successfully!"
echo "========================================"
echo ""
echo "📋 Summary:"
echo "  - Database: ${POSTGRES_DB:-discourse}"
echo "  - Admin: ${ADMIN_EMAIL:-manual creation}"
echo "  - Port: ${APP_PORT:-3000}"
echo ""
echo "🌐 Access Points:"
echo "  - Forum: http://localhost:${APP_PORT:-3000}"
echo "  - Admin: http://localhost:${APP_PORT:-3000}/admin"
echo ""
echo "📚 Useful Commands:"
echo "  - View logs: docker logs -f yunding-app"
echo "  - Stop: docker compose down"
echo "  - Restart: docker compose restart"
echo "  - Rails console: docker compose exec app bundle exec rails console"
echo ""
echo "📖 Documentation:"
echo "  - docs/SECONDARY-DEVELOPMENT.md"
echo "  - docs/YUNDING-EXECUTION-PLAN.md"
echo ""
echo "✨ Happy forum building!"
