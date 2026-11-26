#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_bundle

command -v rpmbuild >/dev/null 2>&1 || {
    echo "rpmbuild is required to build the .rpm" >&2
    exit 1
}

rpmdir="$ROOT/build/rpm"
rm -rf "$rpmdir"
install -d "$rpmdir/BUILD" "$rpmdir/RPMS" "$rpmdir/SOURCES" "$rpmdir/SPECS" "$rpmdir/SRPMS"

work="$ROOT/build/rpm-source"
rm -rf "$work"
install -d "$work/Aura"
cp -a "$DIST/." "$work/Aura/"
install -Dm755 "$ROOT/packaging/launcher/aura" "$work/Aura/aura-launcher"
install -Dm644 "$ROOT/packaging/aura.desktop" "$work/Aura/aura.desktop"
install -Dm644 "$ROOT/LICENSE" "$work/Aura/LICENSE"
install -d "$work/Aura/icons"
size=
for size in "${ICON_SIZES[@]}"; do
    install -Dm644 \
        "$ROOT/packaging/icons/hicolor/${size}x${size}/apps/aura.png" \
        "$work/Aura/icons/${size}.png"
done

tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    -C "$work" -czf "$rpmdir/SOURCES/Aura-${VERSION}-x86_64.tar.gz" Aura

rpmbuild -bb \
    --define "_topdir $rpmdir" \
    --define "version $VERSION" \
    "$ROOT/packaging/rpm/aura-weather.spec"

built="$(find "$rpmdir/RPMS" -name "*.rpm" -type f | head -n 1)"
if [[ -z "$built" ]]; then
    echo "rpmbuild did not produce an RPM" >&2
    exit 1
fi

output="$OUT/aura-weather-${VERSION}-1.x86_64.rpm"
cp "$built" "$output"
echo "Created $output"
