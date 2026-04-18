#!/bin/bash

# SSL 证书配置脚本
# 使用 Let's Encrypt 自动获取和续期 SSL 证书

set -e

echo "🔒 SSL Certificate Setup Script"
echo "================================"

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

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root or use sudo"
    exit 1
fi

# 检查参数
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 forum.yourdomain.com"
    exit 1
fi

DOMAIN=$1

# 检查 Certbot 是否安装
if ! command -v certbot &> /dev/null; then
    print_info "Installing Certbot..."
    apt update
    apt install -y certbot
fi

# 创建 SSL 目录
print_info "Creating SSL directory..."
mkdir -p docker/ssl

# 停止 Nginx（如果正在运行）
print_info "Stopping Nginx if running..."
docker compose stop nginx 2>/dev/null || true

# 获取证书
print_info "Obtaining SSL certificate for $DOMAIN..."
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# 复制证书到项目目录
print_info "Copying certificates to project directory..."
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem docker/ssl/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem docker/ssl/key.pem

# 设置权限
chmod 644 docker/ssl/cert.pem
chmod 600 docker/ssl/key.pem
chown -R $SUDO_USER:$SUDO_USER docker/ssl

# 创建续期脚本
print_info "Creating renewal script..."
cat > scripts/renew-ssl.sh <<'EOF'
#!/bin/bash
# SSL 证书自动续期脚本

DOMAIN=$1
PROJECT_DIR="/opt/yunding-forum"

echo "🔄 Renewing SSL certificate for $DOMAIN..."

# 续期证书
certbot renew --quiet

# 复制新证书
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $PROJECT_DIR/docker/ssl/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $PROJECT_DIR/docker/ssl/key.pem

# 重启 Nginx
cd $PROJECT_DIR
docker compose restart nginx

echo "✅ SSL certificate renewed successfully!"
EOF

chmod +x scripts/renew-ssl.sh

# 添加定时任务
print_info "Adding cron job for auto-renewal..."
(crontab -l 2>/dev/null; echo "0 2 1 * * $PWD/scripts/renew-ssl.sh $DOMAIN >> /var/log/ssl-renewal.log 2>&1") | crontab -

# 启动 Nginx
print_info "Starting Nginx..."
docker compose up -d nginx

print_info "✅ SSL certificate setup completed!"
print_info "Certificate location: docker/ssl/"
print_info "Auto-renewal: Every month at 2:00 AM"
