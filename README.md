# dsh-routing-suite

把 DSH Web 的运行时注入器和两个路由预设放在同一个仓库。这个 Fork 在 Arch Linux 上完成过实际安装和 DSH Web 验证；Windows 也保留一键安装脚本。

[中文](README.md) | [English](README.en.md)

## 适合谁

- 想在 DSH Web 新建会话时选择 `Router Standard (experimental)` 或 `Router Spec (experimental)` 的用户。
- 已经能运行 `dsh web`，但不想手动处理 injector、预设目录和版本号的用户。

## Linux 一键安装

以下流程已在 Arch Linux 实测。开始前请先确认 `dsh web` 本身能正常启动。

```bash
git clone --recurse-submodules https://github.com/wenhao4126/dsh-routing-suite.git
cd dsh-routing-suite
bash install.sh
dsh web
```

安装器会：

1. 从官方 Release 下载并校验 `dsh-super-injector` `v0.3.3`。
2. 放到稳定目录 `~/.local/share/dsh-routing-suite/injector-0.3.3`（若设置了 `XDG_DATA_HOME`，则使用该目录）。
3. 用官方 DSH 命令注册 injector。
4. 安装两个预设到 `~/.dsh/.agent-presets/router-standard` 和 `~/.dsh/.agent-presets/router-spec`。
5. 在每次安装前备份原有 injector、两个预设和 Web profile 的插件文件；不会删除登录信息、会话或整个 `~/.dsh`。

安装前想只检查仓库和系统平台、不改任何文件时：

```bash
bash install.sh --dry-run
```

### Arch Linux 前置条件（已实测）

```bash
sudo pacman -S --needed git curl tar coreutils
```

还需要已可用的 `dsh` 命令。安装器会在开始前检查 `dsh`、`curl`、`tar` 和 `sha256sum`；少任何一个都会停止并说明缺少什么。

### 其他 Linux 发行版（未实测）

脚本只要求 Linux、Bash、`dsh`、`curl`、`tar` 和 `sha256sum`。以下只是常见依赖安装命令，**尚未在这些发行版上实际验证**：

```bash
# Ubuntu / Debian
sudo apt-get install git curl tar coreutils

# Fedora
sudo dnf install git curl tar coreutils
```

## Windows

在 PowerShell 中执行：

```powershell
git clone --recurse-submodules https://github.com/wenhao4126/dsh-routing-suite.git
cd dsh-routing-suite
.\install.ps1
```

Windows 脚本会分别安装两个直接目录，不会把预设嵌套成 `router-standard/router-standard`。本次发布在 Arch Linux 上做了静态检查；尚未在 Windows 实机运行验证。

## 第一次使用与验收

1. 重启 DSH Web：`dsh web`。
2. 打开网页，新建会话。
3. 在预设列表中选择一个：
   - `Router Standard (experimental)`：默认推荐。根据任务自动在计划和执行倾向之间路由，适合日常写代码、排错和一般任务。
   - `Router Spec (experimental)`：更强调先澄清和规划，适合复杂需求、架构设计或不希望模型仓促执行的任务。
4. 在该会话中运行 `dev_plugin_status`，应看到 injector 为 `[active]`。
5. 运行 `dev_self_test`，应看到 `PASS 8/8`。

如果预设没有出现在新会话列表中，先完全停止再重启 `dsh web`，然后确认目录是否存在：

```bash
ls ~/.dsh/.agent-presets/router-standard/agent.cordis.yml
ls ~/.dsh/.agent-presets/router-spec/agent.cordis.yml
```

## 升级、回退与卸载

升级时在本仓库目录执行：

```bash
git pull --ff-only
git submodule update --init --recursive
bash install.sh
```

每次 Linux 安装都会输出一个备份目录，格式类似 `~/.dsh/backups/linux-install-20260820-120000.xxxxxx`。要回退预设，请将备份目录中的 `router-standard` 或 `router-spec` 复制回 `~/.dsh/.agent-presets/`，再重启 DSH Web。Web profile 的 `package.json` 和 `cordis.patch.yml` 也在同一备份目录中，可在需要时恢复。

要卸载 injector：

```bash
dsh plugin --profile web remove @dsh-external/dsh-super-injector
```

随后删除你不再需要的预设目录即可。删除前建议保留安装器生成的备份目录，以便恢复。

## 故障排查

- `缺少依赖`：按安装器提示安装对应命令后重试。
- `SHA-256 校验失败`：不要跳过。可能是网络下载不完整或官方 Release 已变化；重新下载并核对本仓库更新。
- `dev_plugin_status` 不是 `[active]`：重启 `dsh web` 后再检查；仍失败时，从安装器输出的备份目录回退，并在 Issue 中附上错误文字。
- `dev_self_test` 没有 `PASS 8/8`：不要继续升级或覆盖现有备份，先保留错误结果以便排查。

## 组件与来源

| 路径 | 上游仓库 | 固定版本 | 作用 |
|---|---|---:|---|
| `injector/` | [dsh-super-injector](https://github.com/yjh051108/dsh-super-injector) | [v0.3.3](https://github.com/yjh051108/dsh-super-injector/releases/tag/v0.3.3) | DSH 运行时 injector 和 `dev_*` 工具。 |
| `preset/` | [dsh-router-standard](https://github.com/yjh051108/dsh-router-standard) | [v0.2.0](https://github.com/yjh051108/dsh-router-standard/releases/tag/v0.2.0) | `router-standard` 与 `router-spec` 预设。 |

子模块仍归各上游项目维护；此仓库只聚合安装、文档和发布流程。

## 已知限制

`preset/router.test.mjs` 目前仍引用已移除的 `preset/router-core.mjs` 路径，因此在上游 `v0.2.0` 基线中会失败。本仓库的 Linux 安装器测试专门覆盖实际安装行为；不会把该上游基线失败伪装成通过。

## 许可证

MIT。感谢上游项目和 `xiaobright/modeltest`、`xiaobright/dsh-anchored-standard` 的工作。
