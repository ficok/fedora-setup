#!/usr/bin/env bash
# Installs the fonts listed in fonts.list (git repos or zip URLs) into ~/.local/share/fonts.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

list="$ROOT_DIR/fonts.list"
dest="$HOME/.local/share/fonts/linux-setup"
n=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

while read -r kind url _; do
  case "${kind:-}" in ''|'#'*) continue ;; esac
  n=$((n+1)); work="$tmp/$n"; mkdir -p "$work"
  case "$kind" in
    git) git clone --depth=1 --quiet "$url" "$work" || { warn "clone failed: $url"; continue; } ;;
    zip) curl -fsSL "$url" -o "$work/f.zip" && unzip -q -o "$work/f.zip" -d "$work" || { warn "download failed: $url"; continue; } ;;
    *)   warn "unknown font source type: $kind"; continue ;;
  esac
  mkdir -p "$dest"
  find "$work" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp -f {} "$dest/" \;
done < "$list"

if [ "$n" -eq 0 ]; then log "fonts.list is empty; nothing to install."; exit 0; fi
fc-cache -f >/dev/null 2>&1 || true
ok "Fonts installed to $dest."
