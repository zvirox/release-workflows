# release-workflows

Reusable GitHub Actions workflows for uniform Linux packaging and releases across the Starship Control and Linux desktop application ecosystem.

---

## Six-Application Packaging & Release Audit Summary

Conducted on Nov 24, 2026 per the **Uniform Linux Release and Packaging Plan** (@Prakash).

### Cross-App Comparison Matrix

| Repository | GitHub Repo Name | Cargo Bin Name | Tauri Product Name | Existing Workflows | Manifest Versions (Cargo / App / Tauri) | Latest Tag | Formats Currently Built | Rule 3 Conflicts / Discrepancies |
|---|---|---|---|---|---|---|---|---|
| **Starship Control** | `starship-control` | `starship-control` | `Starship Control` | `ci.yml`, `release.yml` | `0.1.0` / `0.1.0` / `0.1.0` | `v0.1.0-alpha.3` | `.deb`, `.rpm`, `.tar.gz` | None. Ready for nfpm. |
| **Agentic Tuneup Pro** | `agentic-tuneup-pro` | `agentic-tuneup-pro` (+ `atpd-helper`) | `Agentic Tuneup Pro` | **None** | `0.1.0` / `0.1.0` / `0.1.0` | `v0.0.4-alpha` | Previously manual `.deb`, `.rpm`, `.pkg.tar.zst`, `.tar.gz`, Flatpak, AUR | **No release workflow in git**; version manifest mismatch against tag `v0.0.4-alpha`. |
| **ScreenStudio Pro** | `screen-studio-pro` | `screen-studio-pro` | `ScreenStudio Pro` | `ci.yml`, `release.yml` | `0.0.1+alpha.9` / `0.0.1+alpha.9` / `0.0.1+alpha.9` | `v0.0.1-alpha.9` | `.deb`, `.rpm`, AppImage (143MB), Flatpak (264MB) | AppImage & Flatpak bloat to delete; Tauri productName produced dot-separated `ScreenStudio.Pro` package name. |
| **Audio Labs Pro** | `audio-labs-pro` | `alp-desktop` (+ `alp-cli`, `alp-infer`) | `Audio Labs Pro` | `ci.yml`, `release.yml` | `0.1.0` / `1.0.0` / `0.1.0` | `v0.0.1-alpha.9` | `.deb`, `.rpm`, Flatpak | **Binary name mismatch** (`alp-desktop` vs repo `audio-labs-pro`); Flatpak job to delete; version mismatch across manifests. |
| **Easy Edits Pro** | `easy-edits-pro` | `saturn-tauri` (+ `saturn-plugin-worker`) | `Easy Edits Pro` | `ci.yml`, `linux-packages.yml` | `0.1.0` / `0.1.0` / `0.1.0` | `v0.1.3-beta.2` | `.deb`, `.rpm`, Flatpak | **Binary name mismatch** (`saturn-tauri` vs repo `easy-edits-pro`); Flatpak to delete; version was dynamically mutated in CI. |
| **Net Watch Pro** | `net-watch-pro` | `netwatch-app` (+ `netwatchd`) | `Net Watch Pro` | `ci.yml`, `hardening.yml`, `release.yml` | `0.9.2-beta.4` / `0.9.2-beta.4` / `0.9.2-beta.4` | `v0.9.2-beta.4` | `.deb`, `.rpm`, `.tar.gz`, AUR source tarball | **Binary name mismatch** (`netwatch-app` vs repo `net-watch-pro`); AUR/tarball to delete; daemon & systemd unit to preserve. |

---

## Rule 3 Conflict Analysis & Proposed Resolution Path

The packaging plan's **Rule 3** mandates:
> *Stop on conflicts. If an audit finds a name mismatch, an existing AUR or Flatpak name that differs from the repo name, versions that do not match the latest tag, or a repo with no release workflow at all, report it and wait. Otherwise continue.*

### 1. Binary Name vs. Repo Name Mismatches
* **Audio Labs Pro**: Repo is `audio-labs-pro`, but `crates/alp-desktop/Cargo.toml` sets `name = "alp-desktop"`.  
  * *Resolution:* Add `[[bin]] name = "audio-labs-pro" path = "src/main.rs"` in `crates/alp-desktop/Cargo.toml` so `cargo build --release` produces `/target/release/audio-labs-pro` natively without post-build bash renaming.
* **Easy Edits Pro**: Repo is `easy-edits-pro`, but `apps/saturn-tauri/Cargo.toml` sets `name = "saturn-tauri"`.  
  * *Resolution:* Add `[[bin]] name = "easy-edits-pro" path = "src/main.rs"` in `apps/saturn-tauri/Cargo.toml` so the output binary is `target/release/easy-edits-pro`.
* **Net Watch Pro**: Repo is `net-watch-pro`, but `app/src-tauri/Cargo.toml` sets `name = "netwatch-app"`.  
  * *Resolution:* Add `[[bin]] name = "net-watch-pro" path = "src/main.rs"` in `app/src-tauri/Cargo.toml`.

### 2. Discontinued Formats to Remove (AppImage, Flatpak, Plain Tarball, AUR)
* **ScreenStudio Pro**: Remove `flatpak` job from `.github/workflows/release.yml`, remove `args: --bundles deb,rpm,appimage`, and delete `packaging/flatpak/`.
* **Audio Labs Pro**: Remove `flatpak` job from `.github/workflows/release.yml` and delete `packaging/flatpak/`.
* **Easy Edits Pro**: Remove `install-proof-flatpak` job from `.github/workflows/linux-packages.yml` and delete `packaging/flatpak/`.
* **Agentic Tuneup Pro**: Delete `packaging/flatpak/`, `packaging/aur/`, and `packaging/appimage/`.
* **Net Watch Pro**: Remove AUR and plain tarball packaging steps from `.github/workflows/release.yml` and delete `packaging/arch/` (nfpm builds `.pkg.tar.zst` directly).

### 3. Version Alignment Across Manifests & Release Tags
* In ATP and ALP, workspace `Cargo.toml` had drifted (`0.1.0` vs tags `v0.0.4-alpha` and `v0.0.1-alpha.9`).
* *Resolution:* Enforce Section 5 of the plan — the git tag is the single source of truth. Synchronize manifests (`package.json`, `Cargo.toml`, `tauri.conf.json`) with the planned release version before tagging.

### 4. Repository with No Release Workflow
* **Agentic Tuneup Pro** previously had no `.github/workflows/release.yml`.
* *Resolution:* ATP implemented `nfpm` packaging and adopted this shared workflow alongside all six repositories.

---

## Locked Release Policy (Final & Enforced)

All six Zvirox Linux desktop repositories (`starship-control`, `screen-studio-pro`, `audio-labs-pro`, `agentic-tuneup-pro`, `easy-edits-pro`, `net-watch-pro`) strictly follow this release manifest:

- **Locked Package Formats:** Every `v*` release produces **only** three native x86_64 packages built by `nfpm` from a single binary build (`packaging/nfpm.yaml`), plus `SHA256SUMS` (and `SHA256SUMS.sig` when `SIGNING_KEY` is provided):
  1. `<app>_<version>_amd64.deb`
  2. `<app>-<version>-1.x86_64.rpm`
  3. `<app>-<version>-1-x86_64.pkg.tar.zst`
- **Retired Formats:** AppImage, Flatpak, Snap, plain `.tar.gz` archives, and AUR packages/repositories are permanently removed from CI and future planning.
- **Verification Standard:** Package install, binary presence, desktop validation, and clean removal are verified automatically in clean CI containers (`ubuntu:22.04`, `ubuntu:24.04`, `fedora:latest`, `archlinux:latest`). Separate manual VM release-package tests are removed from planning requirements.
- **Manifest Version Parity:** CI enforces exact version parity between the git tag (`v<version>`) and `Cargo.toml`, `package.json`, and `tauri.conf.json`.
