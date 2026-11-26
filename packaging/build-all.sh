#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 -m PyInstaller --clean --noconfirm packaging/aura.spec

VERSION="${VERSION:-$(tr -d '\n' < "$ROOT/VERSION")}"
export VERSION

bash packaging/make-portable.sh
bash packaging/make-appimage.sh
bash packaging/make-deb.sh
bash packaging/make-rpm.sh
bash packaging/make-arch.sh

echo
echo "Release assets:"
ls -lh "$ROOT/release"
