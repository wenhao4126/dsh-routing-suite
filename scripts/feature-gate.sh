#!/usr/bin/env bash

# 此脚本只检查已产生的证据，不会修改代码、文档或验收结果。
set -euo pipefail

base_branch="${BASE_BRANCH:-main}"
acceptance_dir="${ACCEPTANCE_DIR:-artifacts/acceptance}"
review_dir="${REVIEW_DIR:-artifacts/review}"
test_result_file="${TEST_RESULT_FILE:-artifacts/test-results/passed}"
failed=0

fail() {
  printf '门禁失败：%s\n' "$1" >&2
  failed=1
}

stable_branch="${base_branch#origin/}"
if git rev-parse --verify --quiet "refs/heads/$stable_branch" >/dev/null; then
  base_ref="$stable_branch"
else
  base_ref="origin/$stable_branch"
fi

branch="${GITHUB_HEAD_REF:-$(git branch --show-current)}"
if [[ -z "$branch" ]]; then
  fail '当前不在普通 Git 分支上，也没有提供 GITHUB_HEAD_REF。'
elif [[ "$branch" == "$stable_branch" ]]; then
  fail "当前在稳定分支 $stable_branch，功能必须在独立分支中开发。"
fi

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  fail "找不到基础分支 $stable_branch 或 $base_ref。"
fi

branch_slug="${branch//\//-}"
acceptance_file="$acceptance_dir/$branch_slug.json"
review_file="$review_dir/$branch_slug.passed"

changed_files="$({
  git diff --name-only "$base_ref"...HEAD 2>/dev/null || true
  git diff --name-only
  git ls-files --others --exclude-standard
} | sort -u)"

code_changed=0
docs_changed=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    CHANGELOG.md|docs/*|README.md|README.en.md|*.md) docs_changed=1 ;;
    install.sh|*.sh|*.ps1|src/*|app/*|lib/*|internal/*|*.go|*.rs|*.py|*.js|*.jsx|*.ts|*.tsx|*.java|*.kt|*.css|*.html)
      code_changed=1 ;;
  esac
done <<< "$changed_files"

if [[ "$code_changed" == 1 && "$docs_changed" == 0 ]]; then
  fail '检测到代码变化，但没有检测到 CHANGELOG、README 或相关说明文档变化。'
fi

if [[ ! -f "$acceptance_file" ]]; then
  fail "缺少 wen-chat 验收报告：$acceptance_file"
elif ! command -v jq >/dev/null 2>&1; then
  fail '缺少 jq，无法读取 wen-chat 验收报告。'
elif ! jq -e '.tool == "wen-chat" and .status == "passed" and (.failed_cases | length == 0)' "$acceptance_file" >/dev/null 2>&1; then
  fail "wen-chat 验收报告不是通过状态：$acceptance_file"
fi

if [[ ! -f "$test_result_file" ]]; then
  fail "缺少自动测试通过标记：$test_result_file"
fi

if [[ ! -f "$review_file" ]]; then
  fail "缺少只读审查通过标记：$review_file"
fi

if [[ "$failed" == 0 ]]; then
  printf '门禁通过：分支、文档、自动测试、wen-chat 验收和只读审查检查均已满足。\n'
else
  printf '请修复以上问题后重新运行门禁。\n' >&2
  exit 1
fi
