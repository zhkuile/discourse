#!/bin/bash

# 数据库初始化脚本
# 用于首次部署时初始化数据库

set -e

echo "🗄️ Database Initialization Script"
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

# 检查环境变量
if [ ! -f .env ]; then
    print_error ".env file not found. Please create it first."
    exit 1
fi

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 检查数据库容器是否运行
if ! docker compose ps postgres | grep -q "Up"; then
    print_error "PostgreSQL container is not running."
    print_info "Start it with: docker compose up -d postgres"
    exit 1
fi

print_info "Waiting for PostgreSQL to be ready..."
until docker compose exec -T postgres pg_isready -U ${POSTGRES_USER:-discourse}; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done

print_info "✅ PostgreSQL is ready!"

# 创建数据库（如果不存在）
print_info "Creating database if not exists..."
docker compose exec -T postgres psql -U ${POSTGRES_USER:-discourse} -tc "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB:-discourse}'" | grep -q 1 || \
docker compose exec -T postgres psql -U ${POSTGRES_USER:-discourse} -c "CREATE DATABASE ${POSTGRES_DB:-discourse}"

# 启用必要的 PostgreSQL 扩展
print_info "Enabling PostgreSQL extensions..."
docker compose exec -T postgres psql -U ${POSTGRES_USER:-discourse} -d ${POSTGRES_DB:-discourse} <<'EOF'
-- 启用 pg_trgm 扩展（用于模糊搜索）
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 启用 hstore 扩展（用于键值存储）
CREATE EXTENSION IF NOT EXISTS hstore;

-- 启用 uuid-ossp 扩展（用于 UUID 生成）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF

print_info "✅ PostgreSQL extensions enabled!"

# 运行数据库迁移
print_info "Running database migrations..."
docker compose exec -T app bundle exec rake db:migrate

print_info "✅ Database migrations completed!"

# 填充种子数据
print_info "Seeding database with initial data..."
docker compose exec -T app bundle exec rake db:seed_fu

print_info "✅ Database seeded!"

# 创建管理员账号（如果配置了）
if [ "$CREATE_ADMIN" = "true" ] && [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
    print_info "Creating admin account..."
    
    # 检查管理员是否已存在
    ADMIN_EXISTS=$(docker compose exec -T app bundle exec rails runner "puts User.find_by(email: '$ADMIN_EMAIL')&.admin?")
    
    if [ "$ADMIN_EXISTS" != "true" ]; then
        docker compose exec -T app bundle exec rake admin:create["$ADMIN_EMAIL","$ADMIN_PASSWORD"] <<EOF
y
EOF
        print_info "✅ Admin account created: $ADMIN_EMAIL"
    else
        print_warn "Admin account already exists: $ADMIN_EMAIL"
    fi
fi

# 创建默认分类和标签
print_info "Creating default categories and tags..."
docker compose exec -T app bundle exec rails runner <<'RUBY'
# 创建分类
categories = [
  { name: "社区公告", color: "3498db", text_color: "FFFFFF", description: "官方通知、系统变更、活动公告、社区规则" },
  { name: "新手专区", color: "2ecc71", text_color: "FFFFFF", description: "新手指引、论坛使用教程、发帖规范、常见问题" },
  { name: "云顶产品", color: "9b59b6", text_color: "FFFFFF", description: "产品介绍、发布动态、使用说明、产品讨论" },
  { name: "大数据技术", color: "3498db", text_color: "FFFFFF", description: "数据平台、数据仓库、实时计算、湖仓一体、数据治理、数据分析" },
  { name: "人工智能", color: "9b59b6", text_color: "FFFFFF", description: "大模型/LLM、AIGC、Agent、RAG/向量数据库、模型部署、AI工程实践" },
  { name: "Web3", color: "f39c12", text_color: "FFFFFF", description: "区块链基础设施、智能合约、链上数据、钱包与身份、DeFi/NFT、Web3安全" },
  { name: "人文", color: "e74c3c", text_color: "FFFFFF", description: "阅读与思考、历史与文化、社会议题、观点讨论" },
  { name: "地理", color: "27ae60", text_color: "FFFFFF", description: "地缘观察、城市与区域、旅行见闻、地图与空间认知" },
  { name: "生活随谈", color: "95a5a6", text_color: "FFFFFF", description: "随便说说、社区闲聊、工作与生活、轻松话题" }
]

admin = User.find_by(admin: true)

categories.each do |cat|
  Category.find_or_create_by!(name: cat[:name]) do |c|
    c.color = cat[:color]
    c.text_color = cat[:text_color]
    c.description = cat[:description]
    c.user_id = admin.id
  end
end

puts "✅ Categories created!"

# 创建标签
tags = [
  "安装部署", "资源分享", "问题求助", "功能建议", "开发编程",
  "使用分享", "使用教程", "请求帮助", "新手指引", "产品咨询",
  "随便说说", "版本更新", "活动公告"
]

tags.each do |tag_name|
  Tag.find_or_create_by!(name: tag_name)
end

puts "✅ Tags created!"
RUBY

print_info "✅ Default categories and tags created!"

# 创建欢迎主题
print_info "Creating welcome topics..."
docker compose exec -T app bundle exec rails runner <<'RUBY'
admin = User.find_by(admin: true)
welcome_category = Category.find_by(name: "社区公告")

if welcome_category && !Topic.find_by(title: "欢迎来到云顶论坛")
  PostCreator.create!(
    admin,
    title: "欢迎来到云顶论坛",
    raw: <<~MD,
      # 欢迎来到云顶论坛 🎉

      云顶论坛是一个面向大数据、人工智能、Web3 及延展话题的专业技术社区。

      ## 关于我们

      - **运营主体**：@ydstack
      - **社区方向**：大数据、人工智能、Web3、人文、地理
      - **社区价值观**：专业、开放、协作、分享

      ## 核心板块

      ### 技术主区
      - 🗄️ **大数据技术**：数据平台、实时计算、湖仓一体
      - 🤖 **人工智能**：大模型、Agent、RAG、AIGC
      - ⛓️ **Web3**：区块链、智能合约、链上数据

      ### 延展社区
      - 📚 **人文**：阅读、历史、文化、社会议题
      - 🌍 **地理**：地缘观察、城市研究、旅行见闻
      - 💬 **生活随谈**：社区闲聊、工作生活

      期待你的参与！
    MD
    category: welcome_category.id,
    pinned_at: Time.zone.now
  )
  puts "✅ Welcome topic created!"
end
RUBY

print_info "✅ Welcome topics created!"

# 数据库优化
print_info "Optimizing database..."
docker compose exec -T postgres psql -U ${POSTGRES_USER:-discourse} -d ${POSTGRES_DB:-discourse} <<'EOF'
-- 分析表统计信息
ANALYZE;

-- 重建索引
REINDEX DATABASE discourse;
EOF

print_info "✅ Database optimized!"

# 创建备份
print_info "Creating initial backup..."
docker compose exec -T app bundle exec rake backup:create

print_info "✅ Initial backup created!"

print_info ""
print_info "🎉 Database initialization completed!"
print_info ""
print_info "Summary:"
print_info "  - Database: ${POSTGRES_DB:-discourse}"
print_info "  - Admin: $ADMIN_EMAIL"
print_info "  - Categories: 9"
print_info "  - Tags: 13"
print_info "  - Welcome topic: Created"
print_info "  - Backup: Created"
print_info ""
print_info "You can now access the forum at: http://localhost:${APP_PORT:-3000}"
