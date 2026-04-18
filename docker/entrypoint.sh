#!/bin/bash
set -e

echo "🚀 Starting Yunding Forum..."

# 等待数据库就绪
echo "⏳ Waiting for database..."
until bundle exec rake db:version > /dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 2
done

echo "✅ Database is ready!"

# 运行数据库迁移
echo "📦 Running database migrations..."
bundle exec rake db:migrate

# 如果是首次运行，创建管理员账号
if [ "$CREATE_ADMIN" = "true" ]; then
  echo "👤 Creating admin account..."
  bundle exec rake admin:create["$ADMIN_EMAIL","$ADMIN_PASSWORD"]
fi

# 执行传入的命令
exec "$@"
