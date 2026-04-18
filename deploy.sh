#!/bin/bash

# 云顶论坛部署脚本
# 用于生产环境的自动化部署

set -e

echo "🚀 Yunding Forum Deployment Script"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 和 Docker Compose
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_info "✅ All dependencies are installed."
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f .env ]; then
        print_warn ".env file not found. Creating from .env.example..."
        cp .env.example .env
        print_warn "Please edit .env file with your configuration before continuing."
        print_warn "Run: nano .env"
        exit 1
    fi
    
    print_info "✅ .env file found."
}

# 拉取最新代码
pull_latest_code() {
    print_info "Pulling latest code from repository..."
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        print_warn "You have uncommitted changes. Stashing..."
        git stash
    fi
    
    # 拉取最新代码
    git pull origin prod
    
    print_info "✅ Code updated successfully."
}

# 创建数据目录
create_data_directories() {
    print_info "Creating data directories..."
    
    mkdir -p data/uploads
    mkdir -p data/backups
    mkdir -p data/logs
    mkdir -p docker/ssl
    
    # 设置权限
    chmod -R 755 data
    
    print_info "✅ Data directories created."
}

# 构建镜像
build_image() {
    print_info "Building Docker image..."
    
    # 使用 docker-compose 构建
    if docker compose version &> /dev/null; then
        docker compose build --no-cache
    else
        docker-compose build --no-cache
    fi
    
    print_info "✅ Docker image built successfully."
}

# 停止旧容器
stop_containers() {
    print_info "Stopping old containers..."
    
    if docker compose version &> /dev/null; then
        docker compose down
    else
        docker-compose down
    fi
    
    print_info "✅ Old containers stopped."
}

# 启动新容器
start_containers() {
    print_info "Starting new containers..."
    
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    print_info "✅ New containers started."
}

# 等待服务就绪
wait_for_service() {
    print_info "Waiting for service to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            print_info "✅ Service is ready!"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - Service not ready yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "Service failed to start within timeout."
    return 1
}

# 显示日志
show_logs() {
    print_info "Showing application logs (Ctrl+C to exit)..."
    
    if docker compose version &> /dev/null; then
        docker compose logs -f app
    else
        docker-compose logs -f app
    fi
}

# 清理旧镜像
cleanup_old_images() {
    print_info "Cleaning up old Docker images..."
    
    docker image prune -f
    
    print_info "✅ Cleanup completed."
}

# 主函数
main() {
    case "$1" in
        deploy)
            check_dependencies
            check_env_file
            pull_latest_code
            create_data_directories
            build_image
            stop_containers
            start_containers
            wait_for_service
            cleanup_old_images
            print_info "🎉 Deployment completed successfully!"
            print_info "Visit: http://localhost:${APP_PORT:-3000}"
            ;;
        build)
            check_dependencies
            build_image
            print_info "✅ Image built successfully."
            ;;
        start)
            check_dependencies
            start_containers
            wait_for_service
            print_info "✅ Service started."
            ;;
        stop)
            check_dependencies
            stop_containers
            print_info "✅ Service stopped."
            ;;
        restart)
            check_dependencies
            stop_containers
            start_containers
            wait_for_service
            print_info "✅ Service restarted."
            ;;
        logs)
            show_logs
            ;;
        status)
            if docker compose version &> /dev/null; then
                docker compose ps
            else
                docker-compose ps
            fi
            ;;
        backup)
            print_info "Creating backup..."
            if docker compose version &> /dev/null; then
                docker compose exec app bundle exec rake backup:create
            else
                docker-compose exec app bundle exec rake backup:create
            fi
            print_info "✅ Backup created."
            ;;
        *)
            echo "Usage: $0 {deploy|build|start|stop|restart|logs|status|backup}"
            echo ""
            echo "Commands:"
            echo "  deploy   - Full deployment (pull code, build image, restart service)"
            echo "  build    - Build Docker image only"
            echo "  start    - Start containers"
            echo "  stop     - Stop containers"
            echo "  restart  - Restart containers"
            echo "  logs     - Show application logs"
            echo "  status   - Show container status"
            echo "  backup   - Create database backup"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
