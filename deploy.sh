#!/bin/bash

# 云顶论坛部署脚本
# 用于生产环境的自动化部署

set -e

resolve_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo ""
    fi
}

run_compose() {
    local compose_cmd
    compose_cmd=$(resolve_compose_cmd)
    if [ -z "$compose_cmd" ]; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    $compose_cmd "$@"
}

# 统一使用 .env 中的数据库配置，避免密码包含特殊字符时拼接 DATABASE_URL 出错

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
    
    # 使用统一的 compose 命令构建
    run_compose build --no-cache
    
    print_info "✅ Docker image built successfully."
}

# 停止旧容器
stop_containers() {
    print_info "Stopping old containers..."
    
    run_compose down
    
    print_info "✅ Old containers stopped."
}

# 启动新容器
start_containers() {
    print_info "Starting new containers..."
    
    run_compose up -d
    
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
        
        if run_compose ps postgres | grep -q "healthy"; then
            echo "Attempt $attempt/$max_attempts - App not ready yet..."
        else
            echo "Attempt $attempt/$max_attempts - Database not healthy yet..."
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "Service failed to start within timeout."
    return 1
}

# 显示日志
show_logs() {
    print_info "Showing application logs (Ctrl+C to exit)..."
    
    run_compose logs -f app
}

# 等待数据库就绪
wait_for_database() {
    print_info "Checking database health..."
    
    local max_attempts=24
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if run_compose ps postgres | grep -q "healthy"; then
            print_info "✅ Database is healthy."
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - Database not healthy yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "Database failed to become healthy within timeout."
    return 1
}

# 清理旧镜像
cleanup_old_images() {
    print_info "Cleaning up old Docker images..."
    
    docker image prune -f
    
    print_info "✅ Cleanup completed."
}

# 记录当前运行中的镜像，用于失败回滚
capture_current_image() {
    CURRENT_APP_IMAGE_ID="$(run_compose images -q app 2>/dev/null || true)"
    if [ -n "$CURRENT_APP_IMAGE_ID" ]; then
        print_info "Captured current app image: $CURRENT_APP_IMAGE_ID"
    else
        print_warn "No current app image found for rollback."
    fi
}

# 回滚到部署前镜像
rollback_deployment() {
    if [ -n "$CURRENT_APP_IMAGE_ID" ]; then
        print_warn "Rolling back to previous app image..."
        docker tag "$CURRENT_APP_IMAGE_ID" yunding-forum:latest
        run_compose up -d --no-build --force-recreate app
        run_compose up -d --no-build --force-recreate sidekiq
        wait_for_service || true
        print_warn "Rollback finished. Check application logs for details."
    else
        print_error "Rollback skipped because no previous image was captured."
    fi
}

# 主函数
main() {
    case "$1" in
        deploy)
            check_dependencies
            check_env_file
            pull_latest_code
            create_data_directories
            capture_current_image
            build_image
            if ! wait_for_database; then
                rollback_deployment
                exit 1
            fi
            stop_containers
            if ! start_containers; then
                rollback_deployment
                exit 1
            fi
            if ! wait_for_service; then
                rollback_deployment
                exit 1
            fi
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
            wait_for_database
            if ! start_containers; then
                exit 1
            fi
            if ! wait_for_service; then
                rollback_deployment
                exit 1
            fi
            print_info "✅ Service started."
            ;;
        stop)
            check_dependencies
            stop_containers
            print_info "✅ Service stopped."
            ;;
        restart)
            check_dependencies
            capture_current_image
            wait_for_database
            stop_containers
            if ! start_containers; then
                rollback_deployment
                exit 1
            fi
            if ! wait_for_service; then
                rollback_deployment
                exit 1
            fi
            print_info "✅ Service restarted."
            ;;
        logs)
            show_logs
            ;;
        status)
            run_compose ps
            ;;
        backup)
            print_info "Creating backup..."
            run_compose exec app bundle exec rake backup:create
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
