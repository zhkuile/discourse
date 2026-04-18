# 云顶论坛生产环境 Docker 镜像
# 基于 Discourse 官方镜像，添加自定义配置

FROM discourse/discourse_dev:20260209-1300

LABEL maintainer="ydstack <contact@ydstack.com>"
LABEL description="Yunding Forum - Professional community for Big Data, AI, and Web3"
LABEL version="1.0.0"

# 设置工作目录
WORKDIR /var/www/discourse

# 复制项目代码
COPY . .

# 设置权限
RUN chown -R discourse:discourse /var/www/discourse

# 安装 Ruby 依赖
RUN bundle install --jobs 4 --deployment --without test development

# 安装 Node.js 依赖
RUN pnpm install --frozen-lockfile

# 预编译资产
RUN bundle exec rake assets:precompile

# 数据库迁移将在启动时执行

# 暴露端口
EXPOSE 3000 4200

# 切换到 discourse 用户
USER discourse

# 启动脚本
COPY docker/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER discourse

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 入口点
ENTRYPOINT ["/entrypoint.sh"]

# 默认命令
CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.conf.rb"]
