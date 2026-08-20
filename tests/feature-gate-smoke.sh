#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

git clone --quiet --no-local "$repo_root" "$tmp/repo"
cd "$tmp/repo"
git checkout --quiet --detach HEAD
base_sha="$(git -C "$repo_root" rev-parse origin/main)"
git update-ref refs/remotes/origin/main "$base_sha"
if git show-ref --verify --quiet refs/heads/main; then
  git branch -D main >/dev/null
fi
cp "$repo_root/scripts/feature-gate.sh" scripts/feature-gate.sh
chmod +x scripts/feature-gate.sh

mkdir -p "$tmp/acceptance" "$tmp/review" "$tmp/test-results"
printf '%s\n' '{"tool":"wen-chat","status":"passed","failed_cases":[]}' \
  > "$tmp/acceptance/feature-linux-installation.json"
touch "$tmp/review/feature-linux-installation.passed" "$tmp/test-results/passed"

BASE_BRANCH=main \
  GITHUB_HEAD_REF=feature/linux-installation \
  ACCEPTANCE_DIR="$tmp/acceptance" \
  REVIEW_DIR="$tmp/review" \
  TEST_RESULT_FILE="$tmp/test-results/passed" \
  bash scripts/feature-gate.sh

printf 'PASS: GitHub Actions 分离提交环境可使用 origin/main 运行门禁。\n'
