#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_bundle

command -v dpkg-deb >/dev/null 2>&1 || {
    echo "dpkg-deb is required to build the .deb" >&2
    exit 1
}

stage="$ROOT/build/deb/${PKG_NAME}_${VERSION}_amd64"
rm -rf "$stage"
install_app_tree "$stage"

installed_kb="$(du -sk "$stage" | cut -f1)"
install -d "$stage/DEBIAN"
cat > "$stage/DEBIAN/control" <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: falsecloud <319977598+falsecloud@users.noreply.github.com>
Installed-Size: ${installed_kb}
Depends: libc6, libstdc++6, libgl1, libegl1, libxkbcommon0, libxkbcommon-x11-0, libwayland-client0, libwayland-cursor0, libwayland-egl1, libxcb-cursor0, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-xinerama0, libxcb-xkb1, libdbus-1-3, libfontconfig1, libfreetype6, libglib2.0-0, libpulse0, libasound2 | libasound2t64, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Homepage: https://github.com/falsecloud/aura
Description: Liquid-glass weather for your desktop
 Aura is a native Qt Quick weather app with real shader-based glass,
 animated condition backdrops, hourly and 10-day forecasts, and saved
 places. Forecast data comes from Open-Meteo and requires no API key.
EOF

output="$OUT/aura-weather_${VERSION}_amd64.deb"
rm -f "$output"
dpkg-deb --build --root-owner-group "$stage" "$output"
dpkg-deb --info "$output" >/dev/null

echo "Created $output"
