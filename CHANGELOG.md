# Changelog

All notable changes to this fork are documented here.

## v0.2.0 - 2026-08-20

### Added

- A Linux `install.sh` that downloads and SHA-256 verifies injector `v0.3.3`, installs it from a stable user-data path, registers it with DSH Web, and installs both presets.
- A repeatable Linux smoke test and a GitHub Actions lifecycle gate.
- Beginner-friendly Chinese and English installation, verification, upgrade, rollback, and troubleshooting guidance.

### Changed

- Arch Linux installation and DSH Web verification are recorded as tested; Ubuntu, Debian, and Fedora directions are explicitly untested references.
- Windows installation now copies `router-standard` and `router-spec` directly instead of nesting the preset directory.
- Documentation now reports the actual pinned preset version, `v0.2.0`.

### Safety and known limits

- Linux reinstalls preserve recoverable backups under `~/.dsh/backups/linux-install-*`; credentials, sessions, and unrelated DSH state are not removed.
- Upstream `preset/router.test.mjs` fails at the `v0.2.0` baseline because it imports the removed `preset/router-core.mjs` path. This is documented rather than treated as a passing project test.
