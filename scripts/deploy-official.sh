#!/bin/bash

# 云顶论坛官方推荐部署脚本
# 使用 discourse_docker 进行生产环境部署

set -e

echo "🚀 Yunding Forum Official Deployment Script"
echo "============================================"

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

# 检查参数
if [ -z "$1" ]; then
    echo "Usage: $0 <domain> <admin-email>"
    echo "Example: $0 forum.yourdomain.com admin@yourdomain.com"
    exit 1
fi

DOMAIN=$1
ADMIN_EMAIL=$2

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root or use sudo"
    exit 1
fi

# 安装 Docker
print_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
fi

# 创建目录
print_info "Creating discourse directory..."
mkdir -p /var/discourse
cd /var/discourse

# 克隆 discourse_docker
if [ ! -d ".git" ]; then
    print_info "Cloning discourse_docker..."
    git clone https://github.com/discourse/discourse_docker.git .
fi

# 创建配置文件
print_info "Creating configuration file..."
cat > containers/app.yml <<EOF
## This is the default configuration file. See also:
## https://github.com/discourse/discourse_docker/blob/master/samples/standalone.yml

templates:
  - "templates/postgres.template.yml"
  - "templates/redis.template.yml"
  - "templates/web.template.yml"
  - "templates/web.ratelimited.template.yml"
  - "templates/web.ssl.template.yml"
  - "templates/web.letsencrypt.ssl.template.yml"

## which TCP/IP ports should this container expose?
## If you want Discourse to share a port with another webserver like Apache or nginx,
## see https://meta.discourse.org/t/17247 for details
expose:
  - "80:80"   # http
  - "443:443" # https

params:
  db_default_text_search_config: "pg_catalog.english"

## Set db_shared_buffers to a max of 25% of the total memory.
## will be set automatically by bootstrap based on detected RAM, or you can override
db_shared_buffers: "256MB"

## can improve sorting performance, but adds memory usage per-connection
#db_work_mem: "40MB"

## Which Git revision should this container use? (default: tests-passed)
#version: tests-passed

env:
  # 云顶论坛配置
  DISCOURSE_HOSTNAME: $DOMAIN
  DISCOURSE_DEVELOPER_EMAILS: '$ADMIN_EMAIL'
  
  # 邮件配置（请修改）
  DISCOURSE_SMTP_ADDRESS: smtp.yourmail.com
  DISCOURSE_SMTP_PORT: 587
  DISCOURSE_SMTP_USER_NAME: your_email@yourmail.com
  DISCOURSE_SMTP_PASSWORD: your_smtp_password
  
  # Let's Encrypt 邮箱
  LETSENCRYPT_ACCOUNT_EMAIL: $ADMIN_EMAIL

## The Docker container is stateless; all data is inside volumes on the machine
## that's running the container.
volumes:
  - volume:
      host: /var/discourse/shared/standalone
      guest: /shared
  - volume:
      host: /var/discourse/shared/standalone/log/var-log
      guest: /var/log

## Plugins go here
## see https://meta.discourse.org/t/19157 for details
hooks:
  after_code:
    - exec:
        cd: \$home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-calendar.git
          - git clone https://github.com/discourse/discourse-data-explorer.git

## Any custom commands to run after building
run:
  - exec: echo "Beginning of custom commands"
  
  ## If you want to set the 'From' email address for your first registration, uncomment and change:
  ## - exec: rails r "SiteSetting.notification_email='noreply@${DISCOURSE_HOSTNAME}'"
  
  - exec: echo "End of custom commands"
EOF

print_info "✅ Configuration file created!"
print_warn ""
print_warn "Please edit /var/discourse/containers/app.yml to configure:"
print_warn "  - SMTP settings (DISCOURSE_SMTP_*)"
print_warn "  - Any other custom settings"
print_warn ""
print_warn "After configuration, run:"
print_warn "  cd /var/discourse"
print_warn "  ./launcher bootstrap app"
print_warn "  ./launcher start app"
print_warn ""
print_info "Configuration file: /var/discourse/containers/app.yml"
print_info "Documentation: https://github.com/discourse/discourse_docker"
