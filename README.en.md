# dsh-routing-suite

One repository for the DSH Web runtime injector and two routing presets. This fork has been installed and verified with DSH Web on Arch Linux. A Windows installer remains available.

[中文](README.md) | [English](README.en.md)

## Who is this for?

- Users who want `Router Standard (experimental)` or `Router Spec (experimental)` in a new DSH Web session.
- Users whose `dsh web` already works and who do not want to manually manage the injector, preset paths, and versions.

## One-command Linux installation

The following flow was tested on Arch Linux. Confirm that `dsh web` itself can start before installing.

```bash
git clone --recurse-submodules https://github.com/wenhao4126/dsh-routing-suite.git
cd dsh-routing-suite
bash install.sh
dsh web
```

The installer downloads and verifies official `dsh-super-injector` `v0.3.3`, stores it at `~/.local/share/dsh-routing-suite/injector-0.3.3` (or `$XDG_DATA_HOME`), registers it through DSH, installs both presets directly, and backs up existing injector, preset, and Web profile plugin files. It does not delete credentials, sessions, or the whole `~/.dsh` directory.

Check repository layout and the platform without writing user files:

```bash
bash install.sh --dry-run
```

### Arch Linux prerequisites (tested)

```bash
sudo pacman -S --needed git curl tar coreutils
```

An operational `dsh` command is also required. The installer checks `dsh`, `curl`, `tar`, and `sha256sum` before changing files.

### Other Linux distributions (not tested)

The script needs Linux, Bash, `dsh`, `curl`, `tar`, and `sha256sum`. These package commands are common references only and have **not** been verified on those distributions:

```bash
# Ubuntu / Debian
sudo apt-get install git curl tar coreutils

# Fedora
sudo dnf install git curl tar coreutils
```

## Windows

Run in PowerShell:

```powershell
git clone --recurse-submodules https://github.com/wenhao4126/dsh-routing-suite.git
cd dsh-routing-suite
.\install.ps1
```

The Windows script copies each preset directory directly, avoiding a `router-standard/router-standard` nesting mistake. It received static checks on Arch Linux, but has not been run on a Windows machine for this release.

## First use and verification

1. Restart DSH Web with `dsh web`.
2. Open the web UI and create a new session.
3. Choose a preset:
   - `Router Standard (experimental)`: the default choice. It routes everyday coding, debugging, and general tasks between planning and execution styles.
   - `Router Spec (experimental)`: prioritizes clarification and planning, suitable for complex requirements and architecture work.
4. In that session, run `dev_plugin_status`. The injector should show `[active]`.
5. Run `dev_self_test`. The result should be `PASS 8/8`.

If the presets do not appear, fully stop and restart `dsh web`, then check:

```bash
ls ~/.dsh/.agent-presets/router-standard/agent.cordis.yml
ls ~/.dsh/.agent-presets/router-spec/agent.cordis.yml
```

## Upgrade, rollback, and removal

Upgrade from the repository directory:

```bash
git pull --ff-only
git submodule update --init --recursive
bash install.sh
```

Each Linux install prints a backup path similar to `~/.dsh/backups/linux-install-20260820-120000.xxxxxx`. To roll back a preset, copy `router-standard` or `router-spec` from that backup back into `~/.dsh/.agent-presets/`, then restart DSH Web. The same backup also preserves the Web profile `package.json` and `cordis.patch.yml` when they existed.

Remove the injector with:

```bash
dsh plugin --profile web remove @dsh-external/dsh-super-injector
```

Then remove only the preset directories you no longer need. Keep the generated backup until the rollback window has passed.

## Troubleshooting

- `Missing dependency`: install the command named by the installer and retry.
- `SHA-256 verification failed`: do not bypass it. Retry the download and check this repository for an updated release.
- Injector is not `[active]`: restart `dsh web`; if it remains inactive, restore the installer backup and open an issue with the error text.
- `dev_self_test` is not `PASS 8/8`: preserve the error result and do not overwrite the backup before investigating.

## Components and attribution

| Path | Upstream repository | Pinned version | Role |
|---|---|---:|---|
| `injector/` | [dsh-super-injector](https://github.com/yjh051108/dsh-super-injector) | [v0.3.3](https://github.com/yjh051108/dsh-super-injector/releases/tag/v0.3.3) | DSH runtime injector and `dev_*` tools. |
| `preset/` | [dsh-router-standard](https://github.com/yjh051108/dsh-router-standard) | [v0.2.0](https://github.com/yjh051108/dsh-router-standard/releases/tag/v0.2.0) | `router-standard` and `router-spec` presets. |

The submodules remain maintained by their upstream projects. This repository provides the combined installation, documentation, and release workflow.

## Known limitation

Upstream `preset/router.test.mjs` still imports the removed `preset/router-core.mjs` path and therefore fails in the `v0.2.0` baseline. The Linux installer smoke test covers real installation behavior; this repository does not present that upstream baseline failure as a passing test.

## License

MIT. Thanks to the upstream projects and to `xiaobright/modeltest` and `xiaobright/dsh-anchored-standard`.
