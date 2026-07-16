#!/usr/bin/env bash
# 一键拉取并部署 yinian-blog
# 用法: ./deploy.sh
set -euo pipefail

CCR_REGISTRY="${CCR_REGISTRY:-ccr.ccs.tencentyun.com}"
CCR_NAMESPACE="${CCR_NAMESPACE:-liuqi_docker}"
SERVICE_REPO="${SERVICE_REPO:-liuqi_test}"
IMAGE_TAG="${IMAGE_TAG:-yinian-blog}"
CONTAINER_NAME="${CONTAINER_NAME:-yinian-blog}"
PORT="${PORT:-7777}"
CONTAINER_PORT="${CONTAINER_PORT:-7777}"

IMAGE="${CCR_REGISTRY}/${CCR_NAMESPACE}/${SERVICE_REPO}:${IMAGE_TAG}"

echo "==> 镜像: ${IMAGE}"
echo "==> 容器: ${CONTAINER_NAME}"
echo "==> 端口: ${PORT} -> ${CONTAINER_PORT}"

if ! docker info >/dev/null 2>&1; then
  echo "错误: Docker 未运行或当前用户无权限" >&2
  exit 1
fi

# 未登录 CCR 时提示登录（已登录会跳过）
if ! grep -q "${CCR_REGISTRY}" "${HOME}/.docker/config.json" 2>/dev/null; then
  echo "==> 未检测到 CCR 登录，请先执行:"
  echo "    docker login ${CCR_REGISTRY} --username=<腾讯云账号ID>"
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
  "$IMAGE"

echo "==> 部署完成"
docker ps --filter "name=^${CONTAINER_NAME}$"
echo
echo "访问: http://localhost:${PORT}"
