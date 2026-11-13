#!/usr/bin/env bash
# Application launcher. Prefers rofi with Wayland support, falls back to fuzzel.
# Creates ~/.local/bin/launcher, which is what the Sway keybindings call.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

if sudo dnf install -y --allowerasing rofi-wayland 2>/dev/null; then
  :
else
  sudo dnf install -y --allowerasing rofi
fi

ver="$(rofi -version 2>/dev/null || true)"
wayland_ok=0
case "$ver" in *wayland*|*Wayland*) wayland_ok=1 ;; esac
major="$(grep -oE '[0-9]+' <<<"$ver" | head -1 || echo 0)"
[ "${major:-0}" -ge 2 ] && wayland_ok=1

if [ "$wayland_ok" -eq 1 ]; then
  # usage: launcher drun | launcher run   (your i3 bindings: $mod+space and $mod+c)
  cat > "$HOME/.local/bin/launcher" <<'WRAP'
#!/bin/sh
exec rofi -config "$HOME/.config/rofi/launcher.rasi" -show "${1:-drun}"
WRAP
  ok "rofi ($ver) will be the launcher."
else
  warn "This rofi build ($ver) has no Wayland support; using fuzzel instead."
  dnf_install fuzzel
  cat > "$HOME/.local/bin/launcher" <<'WRAP'
#!/bin/sh
case "$1" in run) exec fuzzel --list-executables-in-path ;; *) exec fuzzel ;; esac
WRAP
fi
chmod +x "$HOME/.local/bin/launcher"
