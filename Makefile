.PHONY: install dev build serve docker-build docker-push docker-release

CCR_REGISTRY ?= ccr.ccs.tencentyun.com
CCR_NAMESPACE ?= liuqi_docker
SERVICE_REPO ?= liuqi_test
IMAGE_TAG ?= yinian-blog
LOCAL_IMAGE = yinian-blog
REMOTE_IMAGE = $(CCR_REGISTRY)/$(CCR_NAMESPACE)/$(SERVICE_REPO):$(IMAGE_TAG)

install:
	pnpm install

dev:
	pnpm dev

# 构建静态产物
build:
	pnpm build

serve:
	pnpm serve

# 基于 dist 构建本地镜像
docker-build: build
	docker build -t $(LOCAL_IMAGE) .
	@echo "本地镜像: $(LOCAL_IMAGE)"

# 推送到腾讯云（需先 docker login）
docker-push: docker-build
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)
	docker push $(REMOTE_IMAGE)
	@echo "推送完成: $(REMOTE_IMAGE)"

# 一键：构建产物 + 打镜像 + 推送
docker-release: docker-push
