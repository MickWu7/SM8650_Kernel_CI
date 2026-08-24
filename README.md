# SM8650 ReSukiSU Kernel CI

面向三星 Galaxy S24 骁龙版（SM8650 / Snapdragon 8 Gen 3）的专用内核构建与发布仓库。

本仓库基于 Kokuban Kernel CI Center 的构建核心，组合以下固定来源：

- 内核源码：`android_kernel_samsung_sm8650` 的 `resukisu-6.1.99` 分支（基于 `release-KSU-20251028-020628`）
- ReSukiSU：固定为 `v4.1.0`，不会自动跟随 `main`
- SuSFS：`gki-android14-6.1`，默认在构建时动态应用
- 工具链：三星 SM8650 对应的 clang `r487747c` 工具链
- 刷机包：AnyKernel3，设备检查限定为 `e1q`、`e2q`、`e3q`

> 仅适用于三星 Galaxy S24 骁龙系列。刷写自定义内核存在无法启动和数据损坏风险，请先备份原始 `boot.img`，并确认设备代号与固件基线匹配。

## 仓库关系

```text
android_kernel_samsung_sm8650
  push main/resukisu-6.1.99
          |
          | repository_dispatch
          v
SM8650_Kernel_CI
  checkout resukisu-6.1.99 -> inject ReSukiSU v4.1.0
  -> apply SuSFS -> build Image -> package AnyKernel3
  -> upload artifact / optional GitHub Release
```

ReSukiSU 源码仓库可以同时镜像到自己的 GitHub，CI 仍通过固定 tag 校验版本。工具链压缩包体积较大，默认复用上游 release，不需要复制到自己的仓库。

## 第一次启用

1. 在自己的 GitHub 下准备三个仓库：
   - `ReSukiSU`
   - `android_kernel_samsung_sm8650`
   - `SM8650_Kernel_CI`
2. 在 `SM8650_Kernel_CI` 的 Actions 页面手动运行一次 **Build CI Core**。它会创建 `ci-core-latest` release，后续内核工作流从这里取得构建核心。CI 会用 GitHub 提供的仓库 owner 自动解析源码仓库，不需要手工改用户名。
3. 在内核仓库创建 Actions secret `CI_TOKEN`。值使用一个 fine-grained personal access token，至少授予这两个仓库的 Contents 读写权限，用于从内核仓库触发中央构建。
4. 如果内核仓库是私有仓库，也在 `SM8650_Kernel_CI` 创建同名 `CI_TOKEN`，以便中央工作流检出内核源码。
5. 在中央仓库 Actions 页面运行 **Build Kernel**：
   - Project：`s24_sm8650`
   - Branch：`resukisu-6.1.99`
   - Build Mode：`resukisu`
   - ReSukiSU ref：`v4.1.0`
   - SuSFS：开启
   - BBG：按需开启，默认关闭

构建成功后可以先从 Actions Artifacts 下载 ZIP。确认可启动后，再启用 `Create Release` 自动发布。

## 自动构建

内核仓库的 `.github/workflows/trigger-central-build.yml` 会在 `resukisu-6.1.99` 有新提交时触发中央仓库。含 `[skip ci]` 的提交不会触发构建。

固定版本策略：

- 默认 ReSukiSU ref 是 `v4.1.0`。
- 本仓库不启用上游自动更新工作流，避免构建在无人确认时切换 ReSukiSU 版本。
- 手动构建仍可临时覆盖 ref，便于以后测试升级，但正式发布应保持 `v4.1.0`。

## 本地检查与构建

配置和构建计划可以在 macOS 或 Linux 上检查：

```bash
./kokuban validate
./kokuban list
./kokuban plan s24_sm8650 resukisu-6.1.99 resukisu
```

真正的本地内核编译只支持 x86-64 Linux/Ubuntu：

```bash
export KOKUBAN_GITHUB_OWNER="你的 GitHub 用户名"
./kokuban doctor
./kokuban build s24_sm8650 resukisu-6.1.99 resukisu
```

常见选项：

```bash
# 不应用 SuSFS
./kokuban build s24_sm8650 resukisu-6.1.99 resukisu --no-susfs

# 启用 Baseband Guard
./kokuban build s24_sm8650 resukisu-6.1.99 resukisu --with-bbg

# 离线复用已有缓存
./kokuban build s24_sm8650 resukisu-6.1.99 resukisu --offline
```

缓存默认保存在 `~/.cache/kokuban-kernel-ci/`，包含内核 mirror、工具链、AnyKernel3、日志和最终产物。

## 主要文件

- `configs/projects.json`：SM8650 源码、defconfig、工具链、SuSFS 与打包参数
- `configs/anykernel_configs.json`：S24 设备代号和 boot 分区刷写参数
- `.github/workflows/build_kernel.yml`：手动与跨仓库构建入口
- `.github/workflows/build_ci_core.yml`：构建并发布 CI Core
- `ci_core_rs/`：下载工具链、注入 ReSukiSU、编译、打包和发布逻辑

## 上游与许可

本仓库的 CI 核心来源于 [Kokuban Kernel CI Center](https://github.com/YuzakiKokuban/Kokuban_Kernel_CI_Center)，内核来源于 [android_kernel_samsung_sm8650](https://github.com/YuzakiKokuban/android_kernel_samsung_sm8650)，ReSukiSU 来源于 [ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU/tree/v4.1.0)。各组件继续遵循其原始许可证。
