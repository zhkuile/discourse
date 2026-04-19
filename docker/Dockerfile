# 云顶论坛生产环境 Docker 镜像
# 基于 Discourse 官方开发镜像，支持二次开发

FROM discourse/discourse_dev:20260331-0028

LABEL maintainer="ydstack <contact@ydstack.com>"
LABEL description="Yunding Forum - Professional community for Big Data, AI, and Web3"
LABEL version="1.0.0"

# 设置工作目录
WORKDIR /var/www/discourse

# 设置环境变量
ENV RAILS_ENV=production \
    RACK_ENV=production \
    NODE_ENV=production \
    SKIP_ASSET_PRECOMPILE=1

# 复制 Gemfile 和 Gemfile.lock
COPY Gemfile Gemfile.lock ./

# 复制 package.json 和 pnpm-lock.yaml
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# 复制项目代码
COPY . .

# 设置权限
RUN chown -R discourse:discourse /var/www/discourse

# 切换到 discourse 用户
USER discourse

# 安装 Ruby 依赖（包含必要的开发依赖）
RUN bundle config set --local deployment 'true' && \
    bundle install --jobs 4 --retry 3

# 安装 Node.js 依赖
RUN pnpm install --frozen-lockfile

# 暴露端口
EXPOSE 3000

# 启动脚本
COPY docker/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 入口点
ENTRYPOINT ["/entrypoint.sh"]

# 默认命令
CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.conf.rb"]
