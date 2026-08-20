# Linux Installation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tested, reversible Linux installation path and publish it with beginner-friendly bilingual documentation in the public fork.

**Architecture:** A root Bash installer downloads and verifies the pinned injector release, installs it from a stable user-data path, and atomically replaces the two pinned presets after backups. A shell smoke test runs the full installer against a temporary HOME with a local fixture and fake `dsh`; GitHub Actions runs that test and the lifecycle feature gate before merge.

**Tech Stack:** Bash, PowerShell, Git submodules, GitHub Actions, Markdown, jq

---

### Task 1: Define the Linux installer contract with a failing smoke test

**Files:**
- Create: `tests/install-linux-smoke.sh`
- Test: `tests/install-linux-smoke.sh`

- [ ] **Step 1: Create a smoke test that builds a local injector archive**

The test must create a temporary HOME, a minimal npm-style archive containing
`package/package.json`, `package/lib/index.js`, and
`package/cordis.patch.yml`, and a fake `dsh` executable that records arguments.
It computes the fixture checksum and enables test-only URL/checksum overrides
with `DSH_ROUTING_SUITE_TESTING=1`.

```bash
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/package/lib" "$tmp/bin"
printf '{"name":"@dsh-external/dsh-super-injector"}\n' > "$tmp/package/package.json"
printf 'export function apply() {}\n' > "$tmp/package/lib/index.js"
printf '[]\n' > "$tmp/package/cordis.patch.yml"
tar -czf "$tmp/injector.tgz" -C "$tmp" package
sha="$(sha256sum "$tmp/injector.tgz" | awk '{print $1}')"
```

- [ ] **Step 2: Assert dry-run has no user-state side effects**

Run:

```bash
HOME="$tmp/home" DSH_HOME="$tmp/dsh" bash install.sh --dry-run
```

Expected: exit 0, output includes `dry-run`, and neither `$tmp/home` nor
`$tmp/dsh` is created.

- [ ] **Step 3: Assert a full test install uses direct preset paths**

Run the installer with the local archive URL, checksum, fake `dsh`, temporary
HOME, and temporary DSH home. Assert these files exist:

```text
$DSH_HOME/.agent-presets/router-standard/agent.cordis.yml
$DSH_HOME/.agent-presets/router-spec/agent.cordis.yml
$XDG_DATA_HOME/dsh-routing-suite/injector-0.3.3/lib/index.js
```

Assert these incorrect nested paths do not exist:

```text
$DSH_HOME/.agent-presets/router-standard/router-standard
$DSH_HOME/.agent-presets/router-spec/router-spec
```

Assert the fake command recorded:

```text
plugin --profile web add <stable injector path>
```

- [ ] **Step 4: Assert reinstall creates a recoverable backup**

Write a marker into the installed `router-standard/preset.yml`, rerun the
installer, and require the marker under one timestamped directory in
`$DSH_HOME/backups`.

- [ ] **Step 5: Run the test and verify it fails before implementation**

Run:

```bash
bash tests/install-linux-smoke.sh
```

Expected: FAIL because `install.sh` does not exist.

### Task 2: Implement the reversible Linux installer

**Files:**
- Create: `install.sh`
- Test: `tests/install-linux-smoke.sh`

- [ ] **Step 1: Add strict argument and dependency validation**

The script must use `set -euo pipefail`, accept only `--dry-run`, reject
non-Linux systems, and require `dsh`, `curl`, `tar`, and `sha256sum` for a real
install. Dry-run validates repository layout and constants without writing.

```bash
INJECTOR_VERSION='0.3.3'
INJECTOR_SHA256='355238fa8e51bc45c0801066af51e0e122f3b21411b193f601ee54e534391f48'
INJECTOR_URL='https://github.com/yjh051108/dsh-super-injector/releases/download/v0.3.3/dsh-external-dsh-super-injector-0.3.3.tgz'
```

Test overrides are read only when
`DSH_ROUTING_SUITE_TESTING=1`; normal users cannot accidentally replace pinned
metadata through ordinary environment variables.

- [ ] **Step 2: Download, verify, and stage the injector**

Use `mktemp -d` with a cleanup trap. Download with `curl --fail --location
--retry 3`, verify with `sha256sum --check`, extract with
`tar --strip-components=1`, and reject archives missing `package.json`,
`cordis.patch.yml`, or `lib/index.js`.

Install into:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/dsh-routing-suite/injector-0.3.3
```

- [ ] **Step 3: Back up and replace user state**

Create a unique backup using:

```bash
backup_dir="$(mktemp -d "$DSH_HOME/backups/linux-install-$(date +%Y%m%d-%H%M%S).XXXXXX")"
```

Back up existing injector data, both presets, and the Web profile's
`package.json` and `cordis.patch.yml` when present. Stage each replacement
before moving it into its final path. Never delete credentials, sessions, or
the whole profile.

- [ ] **Step 4: Use the official DSH installation command**

Run exactly:

```bash
dsh plugin --profile web add "$injector_target"
```

Print restart, preset selection, `dev_plugin_status`, and `dev_self_test`
instructions plus the backup directory.

- [ ] **Step 5: Run syntax and smoke tests**

Run:

```bash
bash -n install.sh tests/install-linux-smoke.sh
bash tests/install-linux-smoke.sh
```

Expected: PASS, including reinstall backup and no nested preset directories.

- [ ] **Step 6: Commit installer and tests**

```bash
git add install.sh tests/install-linux-smoke.sh
git commit -m "feat: add verified Linux installer"
```

### Task 3: Correct the Windows preset installation path

**Files:**
- Modify: `install.ps1`

- [ ] **Step 1: Replace the single wrapper copy with two direct preset copies**

Use a loop over `router-standard` and `router-spec`. Each source is
`preset\preset\<id>` and each target is
`$env:USERPROFILE\.dsh\.agent-presets\<id>`. Existing targets remain protected
from overwrite and receive a clear message.

- [ ] **Step 2: Run available static checks**

Run `git diff --check`. If `pwsh` exists, parse `install.ps1` with the
PowerShell language parser; otherwise record that PowerShell runtime validation
was unavailable on the Arch Linux host.

### Task 4: Add lifecycle gate and GitHub CI

**Files:**
- Create: `scripts/feature-gate.sh`
- Create: `.github/workflows/feature-gate.yml`
- Create: `artifacts/acceptance/feature-linux-installation.json`
- Create: `artifacts/review/feature-linux-installation.passed`

- [ ] **Step 1: Adapt the lifecycle gate template**

Recognize `GITHUB_HEAD_REF` in detached CI checkouts and classify `*.sh` and
`*.ps1` as code. Require documentation, a generated automatic-test marker, a
passed `wen-chat` JSON report, and a read-only review marker.

- [ ] **Step 2: Add a real CI workflow**

Checkout submodules and run:

```bash
bash -n install.sh tests/install-linux-smoke.sh scripts/feature-gate.sh
bash tests/install-linux-smoke.sh
mkdir -p artifacts/test-results
touch artifacts/test-results/passed
bash scripts/feature-gate.sh
```

Do not invoke the known-broken upstream `preset/router.test.mjs` as if it were
a feature test. It imports the removed `preset/router-core.mjs` path; document
that baseline failure instead.

- [ ] **Step 3: Commit the gate and CI**

```bash
git add scripts/feature-gate.sh .github/workflows/feature-gate.yml
git commit -m "ci: gate Linux installation changes"
```

### Task 5: Write beginner-facing bilingual release documentation

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`
- Create: `CHANGELOG.md`
- Modify: `install.ps1`

- [ ] **Step 1: Update the Chinese README**

Lead with:

```bash
git clone --recurse-submodules https://github.com/wenhao4126/dsh-routing-suite.git
cd dsh-routing-suite
bash install.sh
dsh web
```

Add Arch Linux prerequisites and tested versions, explicitly untested generic
Ubuntu/Debian/Fedora package hints, Windows instructions, first-use preset
selection, Router Standard versus Router Spec, `[active]` and `PASS 8/8`
verification, upgrade, rollback, uninstall, troubleshooting, attribution, and
the upstream preset test limitation.

- [ ] **Step 2: Mirror the content in English**

Keep commands, versions, caveats, checksums, and links equivalent to the
Chinese README.

- [ ] **Step 3: Add the v0.2.0 changelog**

Record Linux installer support, Arch verification, Windows preset layout fix,
CI, known upstream test failure, and rollback behavior under date 2026-08-20.

- [ ] **Step 4: Verify documentation facts**

Confirm the root README says the pinned preset is v0.2.0, all GitHub clone URLs
use the fork, submodule attribution URLs still use upstream, and no document
claims Ubuntu/Debian/Fedora were tested.

- [ ] **Step 5: Commit release documentation**

```bash
git add README.md README.en.md CHANGELOG.md install.ps1
git commit -m "docs: publish Linux installation guide"
```

### Task 6: Run acceptance, security scan, and read-only review

**Files:**
- Create: `artifacts/acceptance/feature-linux-installation.json`
- Create: `artifacts/review/feature-linux-installation.passed`

- [ ] **Step 1: Run all automatic checks**

```bash
bash -n install.sh tests/install-linux-smoke.sh scripts/feature-gate.sh
bash tests/install-linux-smoke.sh
git diff --check origin/main...HEAD
```

- [ ] **Step 2: Verify the live Arch Linux installation**

Require the global DSH 0.1.0-rc.7 path, HTTP 200 from port 3080, a JavaScript
injector client bundle, zero temporary npx links, `dev_plugin_status` active,
and the most recent `dev_self_test` result PASS 8/8.

- [ ] **Step 3: Perform user-view acceptance through `wen-chat`**

Open the feature worktree as the project, verify the README quick start and
expected DSH UI flow, and save a JSON report with `tool: "wen-chat"`,
`status: "passed"`, no failed cases, and the actual timestamp.

- [ ] **Step 4: Scan tracked files and inspect the complete diff**

Search root and both submodules for common API key/private-key patterns without
printing secret values. Perform a read-only review for destructive path bugs,
checksum bypass, accidental private paths, attribution loss, and inaccurate
support claims. Save the review marker only when no high-risk issue remains.

- [ ] **Step 5: Run the mechanical gate and commit evidence**

```bash
mkdir -p artifacts/test-results
touch artifacts/test-results/passed
bash scripts/feature-gate.sh
rm artifacts/test-results/passed
git add artifacts/acceptance artifacts/review
git commit -m "test: record Linux installation acceptance"
```

### Task 7: Push the feature branch and open a pull request

**Files:**
- No new project files

- [ ] **Step 1: Rebase or merge the fork main branch without force-pushing**

Fetch `origin/main`, incorporate it if needed, and rerun the automatic tests.

- [ ] **Step 2: Push the branch**

```bash
git push -u origin feature/linux-installation
```

- [ ] **Step 3: Open a PR against `wenhao4126/dsh-routing-suite:main`**

The PR body lists Linux installer behavior, exact checks, Arch Linux evidence,
the known upstream preset test failure, rollback path, and no unverified Linux
distribution claims.

- [ ] **Step 4: Wait for CI and user acceptance**

Do not merge while CI is pending/failing or before the user explicitly says
the GitHub README and installation flow are accepted.

- [ ] **Step 5: Merge and tag only after acceptance**

Merge the PR, rerun key checks on main, create tag `v0.2.0`, and publish release
notes with upgrade and rollback instructions.
