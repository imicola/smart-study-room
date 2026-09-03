# syntax=docker/dockerfile:1
# ============================================================
# 智能共享自习室预约系统 后端多阶段构建
# 构建阶段: Go 1.27 静态编译（pgx/Gin 纯 Go，无 libpq 依赖）
# 运行阶段: alpine + ca-certificates + tzdata（保证调度器时区语义）
# ============================================================
FROM golang:1.27-alpine AS build
WORKDIR /src

# 先拷贝依赖清单以利用构建缓存
COPY go.mod go.sum ./
RUN go mod download

# 拷贝源码并编译（CGO_ENABLED=0 静态链接，-trimpath 去除构建路径信息）
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM alpine:3.21
RUN apk add --no-cache ca-certificates tzdata
# 预约时间按 Asia/Shanghai 解析(与本地开发时区语义一致)，可用环境变量覆盖
ENV TZ=Asia/Shanghai
COPY --from=build /out/server /usr/local/bin/server
EXPOSE 8080
ENTRYPOINT ["server"]
