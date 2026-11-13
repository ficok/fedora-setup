#!/usr/bin/env bash
# Installs every package named in packages/*.txt (one per line, '#' starts a comment).
set -uo pipefail
. "$(dirname "$0")/../lib/common.sh"

mapfile -t pkgs < <(cat "$ROOT_DIR"/packages/*.txt | sed 's/#.*//' | tr -s ' \t' '\n' | grep -v '^$' | sort -u)
log "Installing ${#pkgs[@]} packages"
dnf_install_lenient "${pkgs[@]}" || warn "dnf reported errors; verifying what actually got installed"

: > "$STATE_DIR/missing-packages.txt"
for p in "${pkgs[@]}"; do
  rpm -q --whatprovides "$p" >/dev/null 2>&1 || echo "$p" >> "$STATE_DIR/missing-packages.txt"
done
if [ -s "$STATE_DIR/missing-packages.txt" ]; then
  warn "Missing: $(tr '\n' ' ' < "$STATE_DIR/missing-packages.txt")"
  exit 1
fi
