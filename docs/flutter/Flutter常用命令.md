---
title: Flutter常用命令
description: Flutter常用命令
category: Flutter
tag:
  - Flutter
---


Flutter 的命令非常丰富，涵盖了从环境配置、项目开发、调试到最终打包发布的整个生命周期。为了让你更直观地掌握这些命令，我将它们按照**使用场景**进行了分类整理。

以下是 Flutter 开发中常用的核心命令汇总：

### 🛠️ 环境与配置管理
在开始开发前，你需要确保环境配置正确。

| 命令 | 作用说明 | 常用场景 |
| :--- | :--- | :--- |
| `flutter doctor` | 检查开发环境依赖 | 诊断 Android SDK, Xcode, Chrome 等是否配置正确。 |
| `flutter doctor -v` | 查看详细诊断信息 | 当普通 doctor 无法定位问题时使用。 |
| `flutter --version` | 查看当前版本信息 | 确认 Flutter、Framework、Engine 及 Dart 的版本。 |
| `flutter upgrade` | 升级 Flutter SDK | 将 SDK 更新到当前频道的最新版本。 |
| `flutter channel` | 查看/切换频道 | 列出 stable, beta, master 等频道。 |
| `flutter channel <name>` | 切换到指定频道 | 例如 `flutter channel stable` 切换到稳定版。 |
| `flutter config` | 配置 Flutter 设置 | 如启用 Web 支持：`flutter config --enable-web`。 |
| `flutter devices` | 查看已连接设备 | 列出所有可用的模拟器或真机及其 ID。 |

### 🚀 开发与运行
这是日常开发中最频繁使用的命令。

*   **`flutter create <项目名>`**：创建一个新的 Flutter 项目。
*   **`flutter run`**：在默认设备上运行应用。
*   **`flutter run -d <device_id>`**：在指定设备上运行（例如 `flutter run -d chrome` 或 `flutter run -d emulator-5554`）。
*   **`flutter run -d windows`**：在 Windows 桌面端运行（需开启桌面支持）。
*   **`flutter attach`**：附加到正在运行的应用。用于在应用已经启动（非通过 flutter run 启动）时开启调试功能，如热重载。

#### 💻 运行时的快捷键（终端中）
当应用正在运行时，终端会监听以下按键：
*   **`r`**：**热重载 (Hot Reload)** - 保持应用状态，快速刷新 UI。
*   **`R`**：**热重启 (Hot Restart)** - 重启应用，重置状态。
*   **`q`**：退出。
*   **`p`**：切换网格叠加层（用于布局检查）。
*   **`w`**：转储渲染树信息。

### 📦 依赖管理
用于管理 `pubspec.yaml` 中的第三方库。

| 命令 | 作用说明 |
| :--- | :--- |
| `flutter pub get` | 获取依赖包。安装 `pubspec.yaml` 中列出的所有包。 |
| `flutter pub upgrade` | 升级依赖包。将所有包升级到 `pubspec.yaml` 允许的最新版本。 |
| `flutter pub add <包名>` | 添加依赖。自动将包名写入 `pubspec.yaml` 并获取。 |
| `flutter pub remove <包名>` | 移除依赖。 |
| `flutter pub outdated` | 查看过期依赖。列出哪些包有新版本可用。 |
| `flutter pub deps` | 查看依赖树。显示项目的依赖层级关系。 |
| `flutter pub cache clean` | 清空本地缓存。当遇到奇怪的下载或版本冲突问题时使用。 |
| `flutter pub cache repair` | 修复缓存。重新验证并修复已安装的包。 |

### 🏗️ 构建与发布
用于生成最终的安装包。

*   **`flutter clean`**：清理项目。删除 `build/` 目录和 `.dart_tool` 等缓存文件，解决构建异常的首选步骤。
*   **`flutter build apk`**：构建 Android APK。
    *   `--debug`：构建调试包（包含调试信息，体积较大）。
    *   `--release`：构建发布包（优化代码，体积小）。
    *   `--split-per-abi`：按 CPU 架构拆分 APK（生成 arm64, armeabi-v7a 等不同包，减小用户下载体积）。
*   **`flutter build appbundle`**：构建 Android App Bundle。用于上传到 Google Play 商店。
*   **`flutter build ios`**：构建 iOS 应用。通常用于生成 `.app` 或打包成 `.ipa`。
*   **`flutter build web`**：构建 Web 应用。生成静态文件用于部署网站。
*   **`flutter build windows` / `macos` / `linux`**：构建对应的桌面端应用。

### 🧪 代码质量与测试
保证代码规范和正确性。

*   **`flutter analyze`**：静态代码分析。检查代码风格、潜在错误（类似 Lint）。
*   **`flutter format .`**：格式化代码。自动将当前目录下所有 Dart 文件格式化为官方推荐风格。
*   **`flutter test`**：运行测试。执行 `test/` 目录下的单元测试和组件测试。
    *   `--coverage`：生成测试覆盖率报告。

### 📱 模拟器管理
直接通过命令行管理模拟器。

*   **`flutter emulators`**：列出所有可用的模拟器。
*   **`flutter emulators --launch <id>`**：启动指定 ID 的模拟器。
*   **`flutter emulators --create`**：创建新的 Android 模拟器。

### 🧰 FVM 常用命令 (Flutter Version Management)
如果你需要在一个电脑上管理多个 Flutter 版本（例如旧项目用旧版，新项目用新版），通常会使用 `fvm` 工具。

| 命令 | 作用说明 |
| :--- | :--- |
| `fvm list` | 列出已安装的 Flutter 版本。 |
| `fvm install <version>` | 安装指定版本的 Flutter。 |
| `fvm use <version>` | 为当前项目指定 Flutter 版本。 |
| `fvm flutter <command>` | 使用 FVM 管理的版本执行 Flutter 命令（例如 `fvm flutter run`）。 |
| `fvm global <version>` | 设置全局默认的 Flutter 版本。 |

### 💡 小贴士
1.  **国内镜像加速**：如果你在中国大陆，建议在环境变量中配置 `PUB_HOSTED_URL` 和 `FLUTTER_STORAGE_BASE_URL` 为国内镜像源（如清华源或官方中文镜像），可以显著提升 `flutter pub get` 和 `flutter upgrade` 的速度。
2.  **遇到问题先 Clean**：绝大多数莫名其妙的编译错误或 IDE 报错，通过执行 `flutter clean` 然后重新 `flutter pub get` 都能解决。
