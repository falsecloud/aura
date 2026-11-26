#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ensure_bundle

archive="$OUT/Aura-${VERSION}-x86_64.tar.gz"
rm -f "$archive"
tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    -C "$(dirname "$DIST")" -czf "$archive" "$(basename "$DIST")"

echo "Created $archive"
