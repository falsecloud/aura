#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_bundle

command -v bsdtar >/dev/null 2>&1 || {
    echo "bsdtar (libarchive) is required to build the Arch package" >&2
    exit 1
}
command -v zstd >/dev/null 2>&1 || {
    echo "zstd is required to build the Arch package" >&2
    exit 1
}

stage="$ROOT/build/arch/pkg"
rm -rf "$stage"
install_app_tree "$stage"

size="$(du -sb "$stage" | cut -f1)"
cat > "$stage/.PKGINFO" <<EOF
pkgname = ${PKG_NAME}
pkgbase = ${PKG_NAME}
pkgver = ${VERSION}-1
pkgdesc = Liquid-glass weather for your desktop
url = https://github.com/falsecloud/aura
builddate = $(date +%s)
packager = falsecloud
size = ${size}
arch = ${ARCH}
license = MIT
depend = glibc
depend = gcc-libs
depend = libxkbcommon
depend = xcb-util-cursor
depend = mesa
depend = fontconfig
depend = dbus
depend = glib2
depend = alsa-lib
depend = gst-plugins-base
depend = gst-plugins-good
EOF

(cd "$stage" && bsdtar -czf .MTREE \
    --format=mtree \
    --options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' \
    .PKGINFO opt usr)

output="$OUT/aura-weather-${VERSION}-1-x86_64.pkg.tar.zst"
rm -f "$output"
(cd "$stage" && bsdtar -cf - .PKGINFO .MTREE opt usr) | zstd -T0 -19 -q -o "$output"

if command -v pacman >/dev/null 2>&1; then
    pacman -Qip "$output" >/dev/null
fi

echo "Created $output"
