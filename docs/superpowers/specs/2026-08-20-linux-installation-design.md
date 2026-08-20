# Linux installation and public fork design

## Goal

Publish the existing suite as the public fork
`wenhao4126/dsh-routing-suite`, while preserving its upstream attribution and
history. Add a beginner-friendly Linux installation path that was verified on
Arch Linux without claiming unperformed distribution testing.

## Scope

- Add a root `install.sh` for Linux.
- Install the injector from the upstream v0.3.3 release archive instead of
  requiring users to build the submodule.
- Verify the release archive with SHA-256
  `355238fa8e51bc45c0801066af51e0e122f3b21411b193f601ee54e534391f48`.
- Copy both `router-standard` and `router-spec` from the pinned preset
  submodule into the correct direct children of `~/.dsh/.agent-presets`.
- Back up an existing injector installation, profile files, and presets before
  replacement.
- Fix the Windows installer so it uses the same direct preset layout and
  installs both presets.
- Update the Chinese and English READMEs with installation, first use,
  verification, upgrade, rollback, and troubleshooting instructions.
- Add a v0.2.0 changelog entry for Linux support.

The installer does not install DSH itself, modify credentials or sessions,
start a persistent service, or vendor built injector artifacts into this
repository.

## Installer design

`install.sh` is a Bash script for Linux with fail-fast behavior. It checks for
`dsh`, `curl`, `tar`, and `sha256sum`, confirms the pinned preset directories
exist, downloads the fixed release asset into a temporary directory, verifies
its checksum, and extracts it into a stable versioned directory below
`~/.local/share/dsh-routing-suite`.

Before changing user state, it creates a timestamped backup below
`~/.dsh/backups`. Existing presets are copied to the backup and then replaced
atomically from the submodule. The script runs the official command
`dsh plugin --profile web add <stable-injector-directory>` only after the
download and preset validation pass. Re-running the script is supported and
must not create an extra preset nesting level.

The script accepts `--dry-run`. Dry-run performs dependency, release metadata,
checksum constant, and source-layout checks without downloading, invoking
`dsh`, or writing under the user's DSH home. This mode is the deterministic CI
and local smoke-test surface.

## Documentation design

The Chinese README leads with a Linux quick start and keeps the Windows path.
The English README mirrors all commands and caveats. The Arch Linux section is
marked as tested with DSH 0.1.0-rc.7, injector 0.3.3, and injector self-test
PASS 8/8. Ubuntu, Debian, and Fedora sections list expected package names but
are explicitly marked as not tested in this environment.

Beginner verification uses only the Web UI:

1. Start `dsh web` and open `http://127.0.0.1:3080`.
2. Create a session with Router Standard (experimental).
3. Ask the agent to call `dev_plugin_status`; expect `[active]`.
4. Ask the agent to call `dev_self_test`; expect `PASS 8/8`.

The documentation explains that Router Standard is the normal default and
Router Spec is the deeper plan-first option. It also records the actual pinned
preset version as v0.2.0, correcting the current v0.3.0 claim.

## Testing and release

- Run `bash -n install.sh`.
- Run `bash install.sh --dry-run`.
- Run installer smoke tests with temporary HOME and fake command dependencies.
- Parse `install.ps1` when PowerShell is available; otherwise report that the
  Windows runtime check was unavailable.
- Scan all tracked root and submodule files for obvious credentials before
  pushing.
- Recheck the live Arch Linux DSH instance: Web HTTP 200, injector client
  bundle registered, plugin active, and `dev_self_test` PASS 8/8.

The upstream preset submodule currently has a pre-existing failing test:
`router.test.mjs` imports the removed path `preset/router-core.mjs` while the
v0.2.0 files live under the two preset directories. This baseline issue is
reported but not fixed or hidden by this feature.

Implementation is committed to `feature/linux-installation` and pushed as a
pull request to the public fork. It is merged and tagged `v0.2.0` only after
technical checks, read-only review, and explicit user acceptance.

## Risks and rollback

The primary runtime risk is replacing an existing user preset or plugin path.
Timestamped backups and stable versioned extraction make rollback explicit.
The public-release risk is accidental disclosure; tracked-file secret scans
and a final diff review gate the push. The fork relationship, upstream remotes,
submodule URLs, and attribution remain intact.
