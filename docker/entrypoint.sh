#!/bin/bash
set -e

echo "🚀 Starting Yunding Forum..."

# 设置环境变量
export RAILS_ENV=${RAILS_ENV:-production}
export RACK_ENV=${RACK_ENV:-production}

# 等待数据库就绪
echo "⏳ Waiting for database..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
  # 尝试连接数据库
  if PGPASSWORD=${DISCOURSE_DB_PASSWORD:-discourse_password} psql -h ${DISCOURSE_DB_HOST:-postgres} -U ${DISCOURSE_DB_USERNAME:-discourse} -d ${DISCOURSE_DB_NAME:-discourse} -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Database connection successful!"
    break
  fi
  
  echo "Database is unavailable - attempt $attempt/$max_attempts"
  sleep 2
  attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
  echo "❌ Database connection failed after $max_attempts attempts"
  echo "Checking database status..."
  
  # 尝试连接到 postgres 数据库（默认存在）
  if PGPASSWORD=${DISCOURSE_DB_PASSWORD:-discourse_password} psql -h ${DISCOURSE_DB_HOST:-postgres} -U ${DISCOURSE_DB_USERNAME:-discourse} -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Can connect to postgres database. Creating discourse database..."
    
    # 创建数据库
    PGPASSWORD=${DISCOURSE_DB_PASSWORD:-discourse_password} psql -h ${DISCOURSE_DB_HOST:-postgres} -U ${DISCOURSE_DB_USERNAME:-discourse} -d postgres -c "CREATE DATABASE ${DISCOURSE_DB_NAME:-discourse};" || true
    
    echo "✅ Database created!"
  else
    echo "❌ Cannot connect to PostgreSQL at all. Please check database configuration."
    exit 1
  fi
fi

# 运行数据库迁移
echo "📦 Running database migrations..."
bundle exec rake db:migrate

# 预编译资产（如果需要）
if [ ! -f "public/assets/.sprockets-manifest-*.json" ] 2>/dev/null; then
  echo "📦 Precompiling assets (this may take a few minutes)..."
  bundle exec rake assets:precompile
  echo "✅ Assets precompiled!"
fi

# 如果是首次运行，创建管理员账号
if [ "$CREATE_ADMIN" = "true" ] && [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
  echo "👤 Creating admin account..."
  
  # 检查管理员是否已存在
  ADMIN_EXISTS=$(bundle exec rails runner "puts User.find_by(email: '$ADMIN_EMAIL')&.admin?" 2>/dev/null || echo "false")
  
  if [ "$ADMIN_EXISTS" != "true" ]; then
    bundle exec rake admin:create["$ADMIN_EMAIL","$ADMIN_PASSWORD"] <<EOF
y
EOF
    echo "✅ Admin account created: $ADMIN_EMAIL"
  else
    echo "ℹ️  Admin account already exists: $ADMIN_EMAIL"
  fi
fi

# 执行传入的命令
echo "🎯 Starting application..."
exec "$@"
