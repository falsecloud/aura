#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '\n' < "$ROOT/VERSION")}"
DIST="${DIST:-$ROOT/dist/Aura}"
OUT="${OUT:-$ROOT/release}"
PKG_NAME="aura-weather"
ARCH="x86_64"
ICON_SIZES=(16 24 32 48 64 128 256 512)

ensure_bundle() {
    if [[ ! -x "$DIST/Aura" ]]; then
        echo "Missing PyInstaller bundle at $DIST/Aura" >&2
        echo "Run: python3 -m PyInstaller --clean --noconfirm packaging/aura.spec" >&2
        exit 1
    fi
    mkdir -p "$OUT"
}

install_app_tree() {
    local dest="$1"
    local size

    install -d "$dest/opt/aura-weather"
    cp -a "$DIST/." "$dest/opt/aura-weather/"
    install -Dm755 "$ROOT/packaging/launcher/aura" "$dest/usr/bin/aura"
    install -Dm644 "$ROOT/packaging/aura.desktop" \
        "$dest/usr/share/applications/aura.desktop"

    for size in "${ICON_SIZES[@]}"; do
        install -Dm644 \
            "$ROOT/packaging/icons/hicolor/${size}x${size}/apps/aura.png" \
            "$dest/usr/share/icons/hicolor/${size}x${size}/apps/aura.png"
    done
}
