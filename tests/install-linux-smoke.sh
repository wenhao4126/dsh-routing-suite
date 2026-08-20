#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

fail() {
  printf '测试失败：%s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "缺少文件 $1"
}

assert_not_exists() {
  [[ ! -e "$1" ]] || fail "不应存在 $1"
}

# 构造一个最小的本地 injector Release，测试无需访问网络。
mkdir -p "$tmp/package/lib" "$tmp/bin"
printf '{"name":"@dsh-external/dsh-super-injector"}\n' > "$tmp/package/package.json"
printf 'export function apply() {}\n' > "$tmp/package/lib/index.js"
printf '[]\n' > "$tmp/package/cordis.patch.yml"
tar -czf "$tmp/injector.tgz" -C "$tmp" package
sha="$(sha256sum "$tmp/injector.tgz" | awk '{print $1}')"

cat > "$tmp/bin/dsh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${DSH_TEST_LOG:?}"
EOF
chmod +x "$tmp/bin/dsh"

dry_home="$tmp/dry-home"
dry_dsh_home="$tmp/dry-dsh"
dry_output="$(
  cd "$repo_root"
  HOME="$dry_home" DSH_HOME="$dry_dsh_home" bash install.sh --dry-run
)"
[[ "$dry_output" == *dry-run* ]] || fail '试运行输出中缺少 dry-run'
assert_not_exists "$dry_home"
assert_not_exists "$dry_dsh_home"

home="$tmp/home"
dsh_home="$tmp/dsh"
data_home="$tmp/data"
command_log="$tmp/dsh-command.log"

run_installer() {
  cd "$repo_root"
  PATH="$tmp/bin:$PATH" \
    HOME="$home" \
    DSH_HOME="$dsh_home" \
    XDG_DATA_HOME="$data_home" \
    DSH_TEST_LOG="$command_log" \
    DSH_ROUTING_SUITE_TESTING=1 \
    DSH_ROUTING_SUITE_INJECTOR_URL="file://$tmp/injector.tgz" \
    DSH_ROUTING_SUITE_INJECTOR_SHA256="$sha" \
    bash install.sh
}

run_installer

injector_target="$data_home/dsh-routing-suite/injector-0.3.3"
standard_target="$dsh_home/.agent-presets/router-standard"
spec_target="$dsh_home/.agent-presets/router-spec"

assert_file "$injector_target/package.json"
assert_file "$injector_target/lib/index.js"
assert_file "$injector_target/cordis.patch.yml"
assert_file "$standard_target/agent.cordis.yml"
assert_file "$spec_target/agent.cordis.yml"
assert_not_exists "$standard_target/router-standard"
assert_not_exists "$spec_target/router-spec"

expected_command="plugin --profile web add $injector_target"
[[ "$(tail -n 1 "$command_log")" == "$expected_command" ]] || \
  fail "dsh 调用不正确，期望：$expected_command"

marker='需要从备份恢复的旧配置'
printf '%s\n' "$marker" >> "$standard_target/preset.yml"
run_installer

backup_match="$(grep -R -l -F -- "$marker" "$dsh_home/backups" | head -n 1 || true)"
[[ -n "$backup_match" ]] || fail '重复安装没有备份原有 router-standard 配置'

printf 'PASS: Linux 安装器试运行、安装路径、DSH 调用和重复安装备份均符合预期。\n'
