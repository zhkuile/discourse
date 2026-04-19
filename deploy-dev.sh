#!/bin/bash

# 云顶论坛二次开发部署脚本
# 支持代码热更新和快速迭代

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

# 自动加载 .env，避免脚本依赖当前 shell 的导出变量
if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

echo "🚀 Yunding Forum Development Deployment Script"
echo "================================================"

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

# 主函数
main() {
    case "$1" in
        init)
            print_step "Initializing deployment..."
            
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
            
            # 创建数据目录
            print_info "Creating data directories..."
            mkdir -p data/uploads data/backups data/logs
            
            # 构建镜像
            print_info "Building Docker image (this may take 10-15 minutes)..."
            run_compose build
            
            # 启动数据库
            print_info "Starting database services..."
            run_compose up -d postgres redis
            
            print_info "Waiting for database to become healthy..."
            for i in $(seq 1 30); do
                if run_compose ps postgres | grep -q "healthy"; then
                    break
                fi
                sleep 2
            done
            
            # 启动应用和 Sidekiq
            print_info "Starting application services..."
            run_compose up -d app sidekiq
            
            print_info "Waiting for app container to stay up..."
            sleep 8
            if run_compose ps app | grep -Eq "Restarting|Exit|unhealthy"; then
                print_error "App container failed during startup. Showing recent logs:"
                run_compose logs --tail=120 app
                exit 1
            fi
            
            print_info "✅ Initialization completed!"
            print_info ""
            print_info "Next steps:"
            print_info "  1. Initialize database: ./deploy-dev.sh init-db"
            print_info "  2. View logs: ./deploy-dev.sh logs"
            print_info "  3. Access forum: http://localhost:${APP_PORT:-3200}"
            ;;
            
        init-db)
            print_step "Initializing database..."
            
            print_info "Checking whether database exists..."
            DB_EXISTS=$(docker exec yunding-postgres psql -U "${POSTGRES_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'")
            if [ "$DB_EXISTS" = "1" ]; then
                print_info "Database ${POSTGRES_DB} already exists. Skipping creation."
            else
                print_info "Creating database..."
                docker exec yunding-postgres psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB}\";"
            fi

            print_info "Ensuring app container is running before migrations..."
            run_compose up -d app
            sleep 5
            if run_compose ps app | grep -Eq "Restarting|Exit|unhealthy"; then
                print_error "App container is not healthy enough to run migrations. Showing recent logs:"
                run_compose logs --tail=120 app
                exit 1
            fi
            
            print_info "Running migrations..."
            run_compose exec -T app bundle exec rake db:migrate
            
            print_info "Seeding database..."
            run_compose exec -T app bundle exec rake db:seed_fu
            
            print_info "Creating admin account..."
            run_compose exec app bundle exec rake admin:create
            
            print_info "✅ Database initialized!"
            ;;
            
        update)
            print_step "Updating deployment..."
            
            # 拉取最新代码
            print_info "Pulling latest code from prod branch..."
            git pull origin prod
            
            # 重新构建镜像
            print_info "Rebuilding Docker image..."
            run_compose build
            
            # 重启服务
            print_info "Restarting services..."
            run_compose down
            run_compose up -d
            
            # 等待服务就绪
            print_info "Waiting for services to be ready..."
            sleep 10
            
            if run_compose ps app | grep -Eq "Restarting|Exit|unhealthy"; then
                print_error "App container failed after update. Showing recent logs:"
                run_compose logs --tail=120 app
                exit 1
            fi
            
            # 运行迁移
            print_info "Running database migrations..."
            run_compose exec -T app bundle exec rake db:migrate
            
            print_info "✅ Update completed!"
            print_info "Access forum: http://localhost:${APP_PORT:-3200}"
            ;;
            
        start)
            print_info "Starting services..."
            run_compose up -d
            print_info "✅ Services started!"
            ;;
            
        stop)
            print_info "Stopping services..."
            run_compose down
            print_info "✅ Services stopped!"
            ;;
            
        restart)
            print_info "Restarting services..."
            run_compose restart
            print_info "✅ Services restarted!"
            ;;
            
        logs)
            run_compose logs -f app
            ;;
            
        console)
            print_info "Opening Rails console..."
            run_compose exec app bundle exec rails console
            ;;
            
        bash)
            print_info "Opening bash shell in container..."
            run_compose exec app bash
            ;;
            
        backup)
            print_info "Creating backup..."
            run_compose exec app bundle exec rake backup:create
            print_info "✅ Backup created!"
            ;;
            
        status)
            run_compose ps
            ;;
            
        clean)
            print_warn "This will remove all containers, volumes, and images."
            read -p "Are you sure? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run_compose down -v
                docker system prune -a
                print_info "✅ Cleanup completed!"
            fi
            ;;
            
        *)
            echo "Usage: $0 {init|init-db|update|start|stop|restart|logs|console|bash|backup|status|clean}"
            echo ""
            echo "Commands:"
            echo "  init      - Initialize deployment (first time setup)"
            echo "  init-db   - Initialize database"
            echo "  update    - Update deployment (pull code, rebuild, restart)"
            echo "  start     - Start services"
            echo "  stop      - Stop services"
            echo "  restart   - Restart services"
            echo "  logs      - Show application logs"
            echo "  console   - Open Rails console"
            echo "  bash      - Open bash shell in container"
            echo "  backup    - Create database backup"
            echo "  status    - Show container status"
            echo "  clean     - Remove all containers and volumes"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
