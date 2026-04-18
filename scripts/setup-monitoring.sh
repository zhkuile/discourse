#!/bin/bash

# 监控配置脚本
# 安装和配置 Prometheus + Grafana 监控系统

set -e

echo "📊 Monitoring Setup Script"
echo "==========================="

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

# 创建监控目录
print_info "Creating monitoring directory..."
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards
mkdir -p monitoring/grafana/dashboards

# 创建 Prometheus 配置
print_info "Creating Prometheus configuration..."
cat > monitoring/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus 自身监控
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Docker 容器监控
  - job_name: 'docker'
    static_configs:
      - targets: ['cadvisor:8080']

  # PostgreSQL 监控
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  # Redis 监控
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  # Node 系统监控
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

# 创建 Grafana 数据源配置
print_info "Creating Grafana datasource configuration..."
cat > monitoring/grafana/provisioning/datasources/datasource.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF

# 创建 Grafana Dashboard 配置
print_info "Creating Grafana dashboard configuration..."
cat > monitoring/grafana/provisioning/dashboards/dashboard.yml <<'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
EOF

# 创建 Docker Compose 监控配置
print_info "Creating monitoring docker-compose configuration..."
cat > monitoring/docker-compose.monitoring.yml <<'EOF'
version: '3.8'

services:
  # Prometheus - 监控数据收集
  prometheus:
    image: prom/prometheus:latest
    container_name: yunding-prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - yunding-network

  # Grafana - 监控可视化
  grafana:
    image: grafana/grafana:latest
    container_name: yunding-grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}
      - GF_INSTALL_PLUGINS=redis-datasource
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana_data:/var/lib/grafana
    ports:
      - "3001:3000"
    networks:
      - yunding-network
    depends_on:
      - prometheus

  # cAdvisor - Docker 容器监控
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: yunding-cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    ports:
      - "8081:8080"
    networks:
      - yunding-network

  # Node Exporter - 系统监控
  node-exporter:
    image: prom/node-exporter:latest
    container_name: yunding-node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - yunding-network

  # PostgreSQL Exporter
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: yunding-postgres-exporter
    restart: unless-stopped
    environment:
      DATA_SOURCE_NAME: "postgresql://${POSTGRES_USER:-discourse}:${POSTGRES_PASSWORD:-discourse_password}@postgres:5432/${POSTGRES_DB:-discourse}?sslmode=disable"
    ports:
      - "9187:9187"
    networks:
      - yunding-network
    depends_on:
      - postgres

  # Redis Exporter
  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: yunding-redis-exporter
    restart: unless-stopped
    environment:
      REDIS_ADDR: "redis://redis:6379"
    ports:
      - "9121:9121"
    networks:
      - yunding-network
    depends_on:
      - redis

networks:
  yunding-network:
    external: true

volumes:
  prometheus_data:
  grafana_data:
EOF

# 创建监控启动脚本
print_info "Creating monitoring start script..."
cat > scripts/start-monitoring.sh <<'EOF'
#!/bin/bash

echo "📊 Starting monitoring services..."

# 创建网络（如果不存在）
docker network create yunding-network 2>/dev/null || true

# 启动监控服务
docker compose -f monitoring/docker-compose.monitoring.yml up -d

echo "✅ Monitoring services started!"
echo ""
echo "Access points:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001"
echo "  - cAdvisor: http://localhost:8081"
echo ""
echo "Grafana default credentials:"
echo "  - Username: admin"
echo "  - Password: admin (or set in .env)"
EOF

chmod +x scripts/start-monitoring.sh

# 创建监控停止脚本
print_info "Creating monitoring stop script..."
cat > scripts/stop-monitoring.sh <<'EOF'
#!/bin/bash

echo "🛑 Stopping monitoring services..."

docker compose -f monitoring/docker-compose.monitoring.yml down

echo "✅ Monitoring services stopped!"
EOF

chmod +x scripts/stop-monitoring.sh

# 创建 Grafana Dashboard（Discourse 监控面板）
print_info "Creating Grafana dashboard for Discourse..."
cat > monitoring/grafana/dashboards/discourse-dashboard.json <<'EOF'
{
  "dashboard": {
    "title": "Yunding Forum Dashboard",
    "tags": ["discourse", "yunding"],
    "timezone": "browser",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "rate(process_cpu_seconds_total{job=\"docker\"}[5m])",
            "legendFormat": "{{name}}"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "gridPos": {"x": 12, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=~\"yunding.*\"}",
            "legendFormat": "{{name}}"
          }
        ]
      },
      {
        "title": "PostgreSQL Connections",
        "type": "graph",
        "gridPos": {"x": 0, "y": 8, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "pg_stat_activity_count",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "Redis Memory",
        "type": "graph",
        "gridPos": {"x": 12, "y": 8, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "redis_memory_used_bytes",
            "legendFormat": "Used Memory"
          }
        ]
      }
    ]
  }
}
EOF

# 更新 .env.example 添加监控配置
print_info "Updating .env.example with monitoring configuration..."
cat >> .env.example <<'EOF'

# ==================== 监控配置 ====================
# Grafana 管理员账号
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_grafana_password
EOF

print_info "✅ Monitoring setup completed!"
print_info ""
print_info "To start monitoring services:"
print_info "  ./scripts/start-monitoring.sh"
print_info ""
print_info "To stop monitoring services:"
print_info "  ./scripts/stop-monitoring.sh"
print_info ""
print_info "Access points:"
print_info "  - Prometheus: http://localhost:9090"
print_info "  - Grafana: http://localhost:3001"
print_info "  - cAdvisor: http://localhost:8081"
