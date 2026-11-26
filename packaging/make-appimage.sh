#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_bundle

tool="${APPIMAGETOOL:-appimagetool}"
if ! command -v "$tool" >/dev/null 2>&1 && [[ ! -x "$tool" ]]; then
    echo "appimagetool not found. Set APPIMAGETOOL to its path." >&2
    exit 1
fi

appdir="$ROOT/build/AppDir"
rm -rf "$appdir"
install -d "$appdir/usr/lib"
cp -a "$DIST" "$appdir/usr/lib/aura"
install -Dm644 "$ROOT/packaging/aura.desktop" "$appdir/aura.desktop"
install -Dm644 "$ROOT/packaging/icons/aura.png" "$appdir/aura.png"

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
set -eu
HERE="${APPDIR:-$(dirname "$(readlink -f "$0")")}"
exec "$HERE/usr/lib/aura/Aura" "$@"
EOF
chmod 755 "$appdir/AppRun"

output="$OUT/Aura-${VERSION}-x86_64.AppImage"
rm -f "$output"
APPIMAGE_EXTRACT_AND_RUN=1 ARCH="$ARCH" "$tool" --no-appstream "$appdir" "$output"

if [[ ! -f "$output" ]]; then
    echo "appimagetool did not produce $output" >&2
    exit 1
fi

echo "Created $output"
