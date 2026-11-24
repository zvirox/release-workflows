## Installation

Download the package matching your distribution from the assets below:

### Ubuntu / Debian / Pop!_OS / Linux Mint
```bash
sudo apt install ./__APP___${VERSION}_amd64.deb
```

### Fedora / RHEL / openSUSE
```bash
sudo dnf install ./__APP___${VERSION}-1.x86_64.rpm
```

### Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -U ./__APP___${VERSION}-1-x86_64.pkg.tar.zst
```

### Verify Checksums
```bash
sha256sum -c SHA256SUMS
```

---
*Notice: AppImage, Flatpak, and AUR builds are deprecated. Releases now exclusively ship official `.deb`, `.rpm`, and `.pkg.tar.zst` native packages.*
