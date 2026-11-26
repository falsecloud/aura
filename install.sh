#!/usr/bin/env bash
set -euo pipefail

REPO="falsecloud/aura"
RELEASES="https://github.com/${REPO}/releases/latest/download"
KEYRING="/etc/apt/keyrings/aura.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/aura.list"
DRY_RUN="${AURA_INSTALL_DRY_RUN:-0}"

say() {
  printf 'aura-install: %s\n' "$*"
}

fail() {
  printf 'aura-install: %s\n' "$*" >&2
  exit 1
}

if [ "$DRY_RUN" != "1" ] && [ "$(id -u)" -ne 0 ]; then
  fail "run this installer with sudo: curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sudo bash"
fi

[ -r /etc/os-release ] || fail "cannot read /etc/os-release; unsupported system"
. /etc/os-release

DISTRO=" ${ID:-} ${ID_LIKE:-} "
command -v curl >/dev/null 2>&1 || fail "curl is required"

case "$DISTRO" in
  *debian*|*ubuntu*)
    command -v apt-get >/dev/null 2>&1 || fail "apt-get was not found"

    if [ "$DRY_RUN" = "1" ]; then
      say "[dry-run] Debian/Ubuntu detected"
      say "[dry-run] add ${KEYRING}"
      say "[dry-run] add APT source ${SOURCE_LIST}"
      say "[dry-run] apt-get update && apt-get install -y aura-weather"
      exit 0
    fi

    install -d -m 0755 /etc/apt/keyrings
    key_tmp="$(mktemp)"
    trap 'rm -f "$key_tmp"' EXIT
    curl -fsSL "$RELEASES/aura-archive-keyring.gpg" -o "$key_tmp"
    install -m 0644 "$key_tmp" "$KEYRING"
    printf 'deb [signed-by=%s] %s/ ./\n' "$KEYRING" "$RELEASES" > "$SOURCE_LIST"

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y aura-weather
    ;;

  *arch*)
    command -v pacman >/dev/null 2>&1 || fail "pacman was not found"

    if [ "$DRY_RUN" = "1" ]; then
      say "[dry-run] Arch Linux detected"
      say "[dry-run] download the latest aura-weather pacman package and run pacman -U"
      exit 0
    fi

    api="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"
    package_url="$(printf '%s' "$api" | grep -o 'https://[^"]*\.pkg\.tar\.zst' | head -n 1)"
    [ -n "$package_url" ] || fail "could not find the latest Arch package"

    package_dir="$(mktemp -d)"
    trap 'rm -rf "$package_dir"' EXIT
    package_file="$package_dir/aura-weather.pkg.tar.zst"
    curl -fL "$package_url" -o "$package_file"
    pacman -U --noconfirm "$package_file"
    ;;

  *)
    fail "unsupported distribution: ${PRETTY_NAME:-unknown}. Supported: Debian/Ubuntu and Arch Linux"
    ;;
esac

say "Aura is installed. Launch it with: aura"
