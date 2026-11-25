#!/usr/bin/env bash
# Smoke test script for Linux packages (deb, rpm, arch)
# Verifies installation, binary presence, dynamic shared-lib links (ldd),
# desktop file validity, and clean uninstallation.
set -euo pipefail

PACKAGE_TYPE="${1:-}"
PACKAGE_FILE="${2:-}"
APP_NAME="${3:-}"
EXPECTED_VERSION="${4:-}"

if [[ -z "$PACKAGE_TYPE" || -z "$PACKAGE_FILE" || -z "$APP_NAME" ]]; then
  echo "Usage: $0 <deb|rpm|arch> <path-to-package> <app-name> [expected-version]" >&2
  exit 1
fi

verify_elf_links() {
  local pkg_files=("$@")
  for bin in "${pkg_files[@]}"; do
    [[ -f "$bin" && -x "$bin" ]] || continue
    # Skip non-ELF wrapper scripts; inspect only native ELF executables.
    if [[ "$(head -c4 "$bin" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]; then
      echo "Checking shared libraries for $bin..."
      local ldd_out
      ldd_out="$(ldd "$bin")"
      if echo "$ldd_out" | grep -q "not found"; then
        echo "$ldd_out" >&2
        echo "❌ Missing shared library detected in $bin" >&2
        exit 1
      fi
    fi
  done
}

echo "=================================================="
echo "Smoke testing $PACKAGE_TYPE package: $PACKAGE_FILE"
echo "App name: $APP_NAME"
echo "=================================================="

case "$PACKAGE_TYPE" in
  deb)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq desktop-file-utils
    echo "Installing debian package..."
    apt-get install -y "$PACKAGE_FILE"

    echo "Verifying installed binary and shared libraries..."
    test -x "/usr/bin/$APP_NAME"
    mapfile -t BINS < <(dpkg -L "$APP_NAME" | grep '^/usr/bin/' || true)
    verify_elf_links "${BINS[@]}"

    if [[ -n "$EXPECTED_VERSION" ]]; then
      "/usr/bin/$APP_NAME" --version | grep -F "$EXPECTED_VERSION"
    fi

    echo "Verifying desktop file..."
    if test -f "/usr/share/applications/$APP_NAME.desktop"; then
      desktop-file-validate "/usr/share/applications/$APP_NAME.desktop"
    fi

    echo "Uninstalling package..."
    apt-get remove -y "$APP_NAME"
    ! test -e "/usr/bin/$APP_NAME"
    echo "✅ Deb package smoke test PASSED."
    ;;

  rpm)
    echo "Installing desktop-file-utils..."
    dnf install -y desktop-file-utils
    echo "Installing RPM package..."
    dnf install -y "$PACKAGE_FILE"

    echo "Verifying installed binary and shared libraries..."
    test -x "/usr/bin/$APP_NAME"
    mapfile -t BINS < <(rpm -ql "$APP_NAME" | grep '^/usr/bin/' || true)
    verify_elf_links "${BINS[@]}"

    if [[ -n "$EXPECTED_VERSION" ]]; then
      "/usr/bin/$APP_NAME" --version | grep -F "$EXPECTED_VERSION"
    fi

    echo "Verifying desktop file..."
    if test -f "/usr/share/applications/$APP_NAME.desktop"; then
      desktop-file-validate "/usr/share/applications/$APP_NAME.desktop"
    fi

    echo "Uninstalling RPM package..."
    dnf remove -y "$APP_NAME"
    ! test -e "/usr/bin/$APP_NAME"
    echo "✅ RPM package smoke test PASSED."
    ;;

  arch)
    pacman -Sy --noconfirm
    pacman -S --noconfirm desktop-file-utils
    echo "Installing Arch package..."
    pacman -U --noconfirm "$PACKAGE_FILE"

    echo "Verifying installed binary and shared libraries..."
    test -x "/usr/bin/$APP_NAME"
    mapfile -t BINS < <(pacman -Qlq "$APP_NAME" | grep '^/usr/bin/' || true)
    verify_elf_links "${BINS[@]}"

    if [[ -n "$EXPECTED_VERSION" ]]; then
      "/usr/bin/$APP_NAME" --version | grep -F "$EXPECTED_VERSION"
    fi

    echo "Verifying desktop file..."
    if test -f "/usr/share/applications/$APP_NAME.desktop"; then
      desktop-file-validate "/usr/share/applications/$APP_NAME.desktop"
    fi

    echo "Uninstalling Arch package..."
    pacman -R --noconfirm "$APP_NAME"
    ! test -e "/usr/bin/$APP_NAME"
    echo "✅ Arch package smoke test PASSED."
    ;;

  *)
    echo "Unknown package type: $PACKAGE_TYPE" >&2
    exit 1
    ;;
esac
