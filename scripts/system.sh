#!/usr/bin/env bash
# System-level services and the Sway login session entry.
set -euo pipefail
. "$(dirname "$0")/../lib/common.sh"

sudo systemctl enable NetworkManager.service bluetooth.service || true
sudo systemctl set-default graphical.target       # minimal installs boot to multi-user.target
# PipeWire / WirePlumber are socket-activated user services; nothing to enable.

sudo install -Dm755 "$ROOT_DIR/scripts/files/sway-session"         /usr/local/bin/sway-session
sudo install -Dm644 "$ROOT_DIR/scripts/files/sway-session.desktop" /usr/share/wayland-sessions/sway-session.desktop
ok "Session 'Sway (linux-setup)' installed."
