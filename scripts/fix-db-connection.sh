#!/bin/bash

# 数据库连接问题修复脚本

set -e

echo "🔧 Database Connection Fix Script"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查数据库容器状态
print_info "Checking database container status..."
docker ps -a | grep yunding-postgres

# 检查数据库日志
print_info "Checking database logs..."
docker logs --tail 50 yunding-postgres

# 检查环境变量
print_info "Checking environment variables..."
if [ -f .env ]; then
    echo "POSTGRES_USER: $(grep POSTGRES_USER .env | cut -d '=' -f2)"
    echo "POSTGRES_DB: $(grep POSTGRES_DB .env | cut -d '=' -f2)"
else
    print_error ".env file not found!"
    exit 1
fi

# 尝试连接数据库
print_info "Testing database connection..."
docker exec -it yunding-postgres psql -U $(grep POSTGRES_USER .env | cut -d '=' -f2) -d postgres -c "SELECT version();"

if [ $? -eq 0 ]; then
    print_info "✅ Database is running and accessible!"
    
    # 检查 discourse 数据库是否存在
    DB_EXISTS=$(docker exec -it yunding-postgres psql -U $(grep POSTGRES_USER .env | cut -d '=' -f2) -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$(grep POSTGRES_DB .env | cut -d '=' -f2)'")
    
    if [ "$DB_EXISTS" != "1" ]; then
        print_warn "Database $(grep POSTGRES_DB .env | cut -d '=' -f2) does not exist. Creating..."
        docker exec -it yunding-postgres psql -U $(grep POSTGRES_USER .env | cut -d '=' -f2) -d postgres -c "CREATE DATABASE $(grep POSTGRES_DB .env | cut -d '=' -f2);"
        print_info "✅ Database created!"
    else
        print_info "✅ Database $(grep POSTGRES_DB .env | cut -d '=' -f2) already exists."
    fi
    
    # 重启应用容器
    print_info "Restarting application container..."
    docker compose restart app
    
    print_info "✅ Fix completed! Check logs with: docker logs -f yunding-app"
else
    print_error "❌ Cannot connect to database. Please check database configuration."
    print_info "Try the following:"
    print_info "  1. Check .env file configuration"
    print_info "  2. Restart database: docker compose restart postgres"
    print_info "  3. Check database logs: docker logs yunding-postgres"
fi
