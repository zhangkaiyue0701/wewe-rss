FROM node:20.16.0-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# 安装特定版本的 pnpm
RUN npm i -g pnpm@8.15.1

FROM base AS build
COPY . /usr/src/app
WORKDIR /usr/src/app

# 使用 --force 重新生成 lockfile
RUN pnpm install --force

RUN pnpm run -r build

RUN pnpm deploy --filter=server --prod /app
RUN pnpm deploy --filter=server --prod /app-sqlite

RUN cd /app && pnpm exec prisma generate

RUN cd /app-sqlite && \
    rm -rf ./prisma && \
    mv prisma-sqlite prisma && \
    pnpm exec prisma generate

FROM base AS app-sqlite
COPY --from=build /app-sqlite /app

WORKDIR /app

# 创建数据目录并设置权限
RUN mkdir -p /data && \
    chown -R node:node /data

# 添加数据卷
VOLUME /data

EXPOSE 3000

ENV NODE_ENV=production
ENV HOST="0.0.0.0"
ENV PORT=3000
ENV SERVER_ORIGIN_URL=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV AUTH_CODE=""
ENV DATABASE_URL="file:/data/wewe-rss.db"
ENV DATABASE_TYPE="sqlite"

RUN chmod +x ./docker-bootstrap.sh

# 切换到非 root 用户
USER node

CMD ["./docker-bootstrap.sh"]
