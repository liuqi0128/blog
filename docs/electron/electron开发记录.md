---
title: electron开发记录
description: electron开发记录
category: Electron
tag:
  - Electron
---

#  electron开发记录
## 1. 开发 electron 中，我为何使用 yarn 进行包管理工具
我之所以在 Electron 项目中选择使用 Yarn 进行包管理，核心原因在于**它能有效避免打包后依赖丢失的问题**。

在进行包安装时，Yarn 会非常严谨地附带下载并解析嵌套的依赖包。例如，当我下载插件 A 时，Yarn 也会自动把 A 插件所依赖的 B、C 插件完整地安装下来。

**为什么要这样做呢？**
因为如果不采用这种严谨的依赖解析方式，项目在本地开发环境下可能一切正常，但一旦将 Electron 打包形成桌面端应用程序（如 `.exe`）后，打开软件时就会直接弹出**缺少该依赖的报错提示**（例如 `Cannot find module 'xxx'`），导致应用白屏或无法运行。Yarn 的包管理机制能确保这些底层依赖（B、C 插件）被正确地包含进最终的安装包中，从而完美规避这个大坑。

> **补充避坑指南：为什么不推荐使用 npm 或 pnpm？**
> 
> **1. npm（可以使用，但偶有不稳）**
> npm 的机制和 Yarn 类似，但它在不同版本间的依赖解析策略经常变动。Electron 打包工具（如 `electron-builder`）在打包时为了减小体积，会主动剔除 `devDependencies`（开发依赖）。在这个剔除过程中，npm 偶尔会出现**误删生产依赖的底层依赖**的情况，导致打包后运行报错。
> 
> **2. pnpm（坑最多，需特殊配置）**
> pnpm 采用了严格的**软链接（symlink）**机制，它的 `node_modules` 不是扁平的。Electron 打包工具在打包成 `.exe` 时，**经常无法正确解析这些软链接**，导致底层依赖根本没有被打包进去。如果一定要在 Electron 中使用 pnpm，通常必须在项目根目录创建一个 `.npmrc` 文件，并强制开启提升机制（`shamefully-hoist=true`），迫使其变成类似 npm/Yarn 的扁平化结构。
> 



## 2.electron 中使用第三方库的重新编译
- serialport   串口操作
- @abandonware/noble  蓝牙操作

> 往往在安装这些库后我们在开发阶段是可以运行的,但是在进行项目打包成exe时,会出现编译不通过打包失败的问题

因为它们是一个原生模块​ (Native Module)，像serialport是用 C++ 编写的,需要针对当前项目的 Node.js 和 Electron 版本进行编译。通常需要运行 **yarn electron-rebuild** 命令重新编译即可

```base
yarn electron-rebuild
```

当然运行 **yarn electron-rebuild** 运行该命令时编译的过程中所依赖的环境有问题,也会编译错误

- Node版本 : v20.19.3
- [Visual Studio Build Tools](https://www.gyan.dev/ffmpeg/builds/)  :选择 MSVC v143 + Windows 10/11 SDK + C++ CMake 工具 
- [Python-3.11](https://wwamx.lanzouw.com/igskL3ktd2ud) : v3.11

以上配置是我在开发 electron 中搭配环境最适合一套,可以完美的重新编译第三方插件