<h1 align="center"> VitePress @sugarat/theme </h1>

<p align="center">
简约风的 <a href="https://theme.sugarat.top"  target="_blank"target="_blank">VitePress 随笔主题</a> 示例运行项目。
</p>

<p align="center">
    <a href="https://atqq.github.io/vitepress-blog-sugar-template/" target="_blank">GitHub Pages Demo</a>
</p>

## Usage

先安装 `pnpm`

```sh
npm i -g pnpm
```

安装依赖

```sh
pnpm install
```

开发启动

```sh
pnpm dev
```

构建

```sh
pnpm build
```

预览产物

```sh
pnpm serve
```

## Docker 镜像（腾讯云 CCR）

镜像地址：`ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:yinian-blog`

本地构建并推送：

```sh
pnpm build
docker build -t yinian-blog .
docker login ccr.ccs.tencentyun.com --username=1229336303
docker tag yinian-blog ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:yinian-blog
docker push ccr.ccs.tencentyun.com/liuqi_docker/liuqi_test:yinian-blog
```

服务器拉取并运行（或用一键脚本）：

```sh
docker login ccr.ccs.tencentyun.com
chmod +x deploy.sh
./deploy.sh
```
