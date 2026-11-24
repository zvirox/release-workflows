#!/usr/bin/env bash
# Smoke test script for Linux packages (deb, rpm, arch)
# Verifies installation, binary location, desktop file validity, and clean uninstallation.
set -euo pipefail

PACKAGE_TYPE="${1:-}"
PACKAGE_FILE="${2:-}"
APP_NAME="${3:-}"

if [[ -z "$PACKAGE_TYPE" || -z "$PACKAGE_FILE" || -z "$APP_NAME" ]]; then
  echo "Usage: $0 <deb|rpm|arch> <path-to-package> <app-name>" >&2
  exit 1
fi

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
    
    echo "Verifying installed binary..."
    test -x "/usr/bin/$APP_NAME"
    
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
    
    echo "Verifying installed binary..."
    test -x "/usr/bin/$APP_NAME"
    
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
    
    echo "Verifying installed binary..."
    test -x "/usr/bin/$APP_NAME"
    
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
