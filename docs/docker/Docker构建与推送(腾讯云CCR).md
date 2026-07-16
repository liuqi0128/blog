---
title: Docker 构建与推送（腾讯云 CCR）
description: Docker 构建与推送（腾讯云 CCR）
category: Docker
tag:
  - Docker
---

## Docker 构建与推送（腾讯云 CCR）

按顺序执行即可。

### 1. 前置准备

1. 本机已准备好 Docker 环境（`docker` 命令可用）
2. 在腾讯云控制台创建镜像仓库，地址示例：

```text
ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test
```

说明：同一仓库下用 **服务名 + 版本号** 作为 tag，例如：

```text
gin-pro-v1.0.0
gin-pro-v1.0.1
user-service-v1.0.0
```

这样既能区分多个服务，也能按版本回溯，避免互相覆盖。

不同版本 tag **互不覆盖**（只有同名 tag 才会被覆盖）；回退时拉对应旧版本即可，例如：

```bash
docker pull ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
```

### 2. 进入项目目录

```bash
cd gin_pro
```

### 3. 登录腾讯云镜像仓库

```bash
docker login ccr.ccs.tencentyun.com --username=1229336303
```

按提示输入：

- 用户名：腾讯云账号 ID（在容器镜像服务控制台可查）
- 密码：镜像仓库独立密码（在控制台「访问凭证」里设置）

若需切换账号，先退出当前登录再重新登录：

```bash
docker logout ccr.ccs.tencentyun.com
docker login ccr.ccs.tencentyun.com --username=<新账号ID>
```

### 4. 本地构建

```bash
# 本地编译前端 + 静态链接 Go 二进制（CGO_ENABLED=0）
make build

# 构建本地镜像
docker build -t gin_pro:local .
```

### 5. 本地测试运行（可选）

```bash
docker run --rm -p 8080:8080 \
  -e GIN_MODE=release \
  gin_pro:local
```

验证：

```bash
curl http://localhost:8080/api/health
```

浏览器访问：http://localhost:8080

按 `Ctrl+C` 停止容器。

### 6. 打标签并推送

目标地址示例：

```text
ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
```

```bash
docker tag gin_pro:local ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
docker push ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
```

推送其他服务 / 版本时改 tag：

```bash
docker tag gin_pro:local ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.1
docker push ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.1

docker tag gin_pro:local ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:user-service-v1.0.0
docker push ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:user-service-v1.0.0
```

### 7. 完整流程一览

```text
make build / docker build  →  本地构建镜像
docker run                 →  本地测试（可选）
docker login               →  登录腾讯云
docker tag + docker push   →  上传到腾讯云
```

### 8. 服务器上拉取并运行

```bash
docker login ccr.ccs.tencentyun.com

docker pull ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0

docker stop gin-pro 2>/dev/null; docker rm gin-pro 2>/dev/null

docker run -d --name gin-pro --restart always -p 8080:8080 \
  -e GIN_MODE=release \
  ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
```

验证：

```bash
docker ps
docker logs gin-pro
curl http://localhost:8080/api/health
```

成功时 `docker ps` 应看到 `Up`，且端口为 `0.0.0.0:8080->8080/tcp`。

### 9. 扩展：一键脚本构建并推送

熟悉上述步骤后，可用一条命令完成构建 + 打标签 + 推送（按需改版本号）：

```bash
make build && \
docker build -t gin_pro:local . && \
docker tag gin_pro:local ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0 && \
docker push ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:gin-pro-v1.0.0
```

或使用 Makefile：

```bash
.PHONY: dev dev-web run-dev build-web build run tidy docker-build docker-push

BACKEND_PORT ?= 8080
VITE_URL ?= http://localhost:5173
GOPATH := $(shell go env GOPATH)
AIR := $(GOPATH)/bin/air

# 腾讯云镜像配置
# 同仓库多服务：SERVICE_NAME 区分服务；VERSION 为版本号
# 最终标签：$(SERVICE_NAME)-$(VERSION)，例如 gin-pro-v1.0.0
CCR_REGISTRY ?= ccr.ccs.tencentyun.com
CCR_NAMESPACE ?= liuqi_docker
SERVICE_REPO ?= liuqi_test
SERVICE_NAME ?= gin-pro
VERSION ?= v1.0.0
IMAGE_TAG ?= $(SERVICE_NAME)-$(VERSION)
LOCAL_IMAGE = gin_pro:local
REMOTE_IMAGE = $(CCR_REGISTRY)/$(CCR_NAMESPACE)/$(SERVICE_REPO):$(IMAGE_TAG)

dev-web:
	cd web && BACKEND_PORT=$(BACKEND_PORT) pnpm dev

run-dev:
	$(AIR)

# 一条命令同时启动 Vite + Go（Go 代码改动自动重启）
dev:
	@test -x $(AIR) || (echo "未找到 air，请先执行: go install github.com/air-verse/air@latest" && exit 1)
	@trap 'kill 0' INT TERM; \
	echo "启动 Vite (5173) + Go ($(BACKEND_PORT)，Air 热重载)..."; \
	echo "浏览器访问: http://localhost:$(BACKEND_PORT)"; \
	cd web && BACKEND_PORT=$(BACKEND_PORT) pnpm dev & \
	sleep 2 && $(AIR) & \
	wait

build-web:
	cd web && pnpm build

build: build-web
	CGO_ENABLED=0 GOOS=linux go build -o bin/gin_pro .

run: build
	./bin/gin_pro

tidy:
	go mod tidy

# 构建 Docker 镜像
docker-build: build
	docker build -t $(LOCAL_IMAGE) .

# 推送到腾讯云（需先 docker login ccr.ccs.tencentyun.com）
docker-push: docker-build
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)
	docker push $(REMOTE_IMAGE)
	@echo "推送完成: $(REMOTE_IMAGE)"
```

### 10. 扩展：一键脚本拉取镜像并部署

```bash
#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   ./deploy.sh --name gin-pro -v 1.0.1
#   ./deploy.sh -n gin-pro -v v1.0.1 --port 8080

CCR_REGISTRY="${CCR_REGISTRY:-ccr.ccs.tencentyun.com}"
CCR_NAMESPACE="${CCR_NAMESPACE:-liuqi_docker}"
SERVICE_REPO="${SERVICE_REPO:-liuqi_test}"

NAME=""
VERSION=""
PORT="${PORT:-8080}"
CONTAINER_PORT="${CONTAINER_PORT:-8080}"

usage() {
  cat <<'EOF'
用法:
  ./deploy.sh --name <服务名> -v <版本号> [选项]

示例:
  ./deploy.sh --name gin-pro -v 1.0.1
  ./deploy.sh -n gin-pro -v v1.0.1 --port 8080

选项:
  -n, --name <name>     服务名（对应镜像 tag 前缀，如 gin-pro）
  -v, --version <ver>   版本号（1.0.1 或 v1.0.1 均可）
  -p, --port <port>     宿主机端口，默认 8080
      --container-port  容器内端口，默认 8080
  -h, --help            显示帮助

环境变量（可选）:
  CCR_REGISTRY    默认 ccr.ccs.tencentyun.com
  CCR_NAMESPACE   默认 liuqi_docker
  SERVICE_REPO    默认 liuqi_test
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      NAME="${2:-}"
      shift 2
      ;;
    -v|--version)
      VERSION="${2:-}"
      shift 2
      ;;
    -p|--port)
      PORT="${2:-}"
      shift 2
      ;;
    --container-port)
      CONTAINER_PORT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$NAME" || -z "$VERSION" ]]; then
  echo "错误: 必须指定 --name 和 -v" >&2
  usage
  exit 1
fi

# 统一版本号为 vX.Y.Z
if [[ "$VERSION" != v* ]]; then
  VERSION="v${VERSION}"
fi

IMAGE_TAG="${NAME}-${VERSION}"
IMAGE="${CCR_REGISTRY}/${CCR_NAMESPACE}/${SERVICE_REPO}:${IMAGE_TAG}"
CONTAINER_NAME="${NAME}"

echo "==> 镜像: ${IMAGE}"
echo "==> 容器: ${CONTAINER_NAME}"
echo "==> 端口: ${PORT} -> ${CONTAINER_PORT}"

if ! docker info >/dev/null 2>&1; then
  echo "错误: Docker 未运行或当前用户无权限" >&2
  exit 1
fi

echo "==> 拉取镜像..."
docker pull "$IMAGE"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "==> 停止并删除旧容器: ${CONTAINER_NAME}"
  docker stop "$CONTAINER_NAME" >/dev/null || true
  docker rm "$CONTAINER_NAME" >/dev/null || true
fi

echo "==> 启动新容器..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart always \
  -p "${PORT}:${CONTAINER_PORT}" \
  -e GIN_MODE=release \
  "$IMAGE"

echo "==> 清理本服务旧版本镜像（不影响等其他服务镜像）..."
REPO_PREFIX="${CCR_REGISTRY}/${CCR_NAMESPACE}/${SERVICE_REPO}"
# 匹配同仓库下该服务的所有 tag，例如 gin-pro-v1.0.0、gin-pro-v1.0.1
while IFS= read -r old_image; do
  [[ -z "$old_image" ]] && continue
  if [[ "$old_image" == "$IMAGE" ]]; then
    continue
  fi
  echo "    删除: ${old_image}"
  docker rmi "$old_image" >/dev/null 2>&1 || true
done < <(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "^${REPO_PREFIX}:${NAME}-")

echo "==> 部署完成"
docker ps --filter "name=^${CONTAINER_NAME}$"
echo
echo "验证: curl http://localhost:${PORT}/api/health"

```
