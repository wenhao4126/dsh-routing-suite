#!/usr/bin/env bash

set -euo pipefail

INJECTOR_VERSION='0.3.3'
INJECTOR_SHA256='355238fa8e51bc45c0801066af51e0e122f3b21411b193f601ee54e534391f48'
INJECTOR_URL='https://github.com/yjh051108/dsh-super-injector/releases/download/v0.3.3/dsh-external-dsh-super-injector-0.3.3.tgz'

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry_run=0

if [[ "${1:-}" == '--dry-run' ]]; then
  dry_run=1
  shift
fi
if [[ "$#" -ne 0 ]]; then
  printf '用法：bash install.sh [--dry-run]\n' >&2
  exit 2
fi

if [[ "$(uname -s)" != 'Linux' ]]; then
  printf '此安装器仅支持 Linux；Windows 请使用 install.ps1。\n' >&2
  exit 1
fi

standard_source="$script_dir/preset/preset/router-standard"
spec_source="$script_dir/preset/preset/router-spec"
for source in "$standard_source" "$spec_source"; do
  [[ -f "$source/agent.cordis.yml" && -f "$source/preset.yml" ]] || {
    printf '预设目录不完整：%s\n' "$source" >&2
    exit 1
  }
done

if [[ "$dry_run" == 1 ]]; then
  printf 'dry-run：已检查 Linux 环境、固定 injector v%s 和两个预设目录；未写入用户目录。\n' "$INJECTOR_VERSION"
  exit 0
fi

for command_name in dsh curl tar sha256sum; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf '缺少依赖：%s\n' "$command_name" >&2
    exit 1
  }
done

home_dir="${HOME:?HOME 未设置}"
dsh_home="${DSH_HOME:-$home_dir/.dsh}"
data_home="${XDG_DATA_HOME:-$home_dir/.local/share}"
injector_target="$data_home/dsh-routing-suite/injector-$INJECTOR_VERSION"
backup_root="$dsh_home/backups"

download_url="$INJECTOR_URL"
download_sha256="$INJECTOR_SHA256"
if [[ "${DSH_ROUTING_SUITE_TESTING:-0}" == 1 ]]; then
  download_url="${DSH_ROUTING_SUITE_INJECTOR_URL:-$download_url}"
  download_sha256="${DSH_ROUTING_SUITE_INJECTOR_SHA256:-$download_sha256}"
fi

work_dir="$(mktemp -d)"
cleanup() {
  rm -rf -- "$work_dir"
}
trap cleanup EXIT

archive="$work_dir/injector.tgz"
printf '下载并校验 dsh-super-injector v%s...\n' "$INJECTOR_VERSION"
curl --fail --location --retry 3 --silent --show-error "$download_url" --output "$archive"
printf '%s  %s\n' "$download_sha256" "$archive" | sha256sum --check --status || {
  printf 'injector SHA-256 校验失败，已停止安装。\n' >&2
  exit 1
}

mkdir -p "$work_dir/injector"
tar -xzf "$archive" --strip-components=1 -C "$work_dir/injector"
for required_file in package.json cordis.patch.yml lib/index.js; do
  [[ -f "$work_dir/injector/$required_file" ]] || {
    printf 'injector 压缩包缺少文件：%s\n' "$required_file" >&2
    exit 1
  }
done

mkdir -p "$backup_root"
backup_dir="$(mktemp -d "$backup_root/linux-install-$(date +%Y%m%d-%H%M%S).XXXXXX")"
printf '备份原有配置到：%s\n' "$backup_dir"

backup_if_present() {
  local source="$1"
  local destination="$2"
  if [[ -e "$source" ]]; then
    cp -R -- "$source" "$destination"
  fi
}

backup_if_present "$injector_target" "$backup_dir/injector-$INJECTOR_VERSION"
backup_if_present "$dsh_home/.agent-presets/router-standard" "$backup_dir/router-standard"
backup_if_present "$dsh_home/.agent-presets/router-spec" "$backup_dir/router-spec"
backup_if_present "$dsh_home/profiles/web/package.json" "$backup_dir/profile-web-package.json"
backup_if_present "$dsh_home/profiles/web/cordis.patch.yml" "$backup_dir/profile-web-cordis.patch.yml"

mkdir -p "$(dirname "$injector_target")" "$work_dir/presets/router-standard" "$work_dir/presets/router-spec"
cp -R -- "$standard_source/." "$work_dir/presets/router-standard/"
cp -R -- "$spec_source/." "$work_dir/presets/router-spec/"

if [[ -e "$injector_target" ]]; then
  mv -- "$injector_target" "$work_dir/old-injector"
fi
mv -- "$work_dir/injector" "$injector_target"

replace_preset() {
  local name="$1"
  local staged="$2"
  local target="$dsh_home/.agent-presets/$name"
  if [[ -e "$target" ]]; then
    mv -- "$target" "$work_dir/old-$name"
  fi
  mkdir -p "$(dirname "$target")"
  mv -- "$staged" "$target"
}

replace_preset router-standard "$work_dir/presets/router-standard"
replace_preset router-spec "$work_dir/presets/router-spec"

printf '注册 injector 到 DSH Web 配置...\n'
dsh plugin --profile web add "$injector_target"

printf '\n安装完成。\n'
printf '1. 重启 DSH Web 服务。\n'
printf '2. 新建会话时选择 Router Standard (experimental)；需要严格路由时选择 Router Spec (experimental)。\n'
printf '3. 在会话中运行 dev_plugin_status，确认 injector 显示 [active]。\n'
printf '4. 运行 dev_self_test，确认结果为 PASS 8/8。\n'
printf '如需回退，备份位于：%s\n' "$backup_dir"
