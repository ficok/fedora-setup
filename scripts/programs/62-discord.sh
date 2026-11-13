#!/usr/bin/env bash
# Discord: RPM Fusion package if it exists (dnf keeps it updated), otherwise the official tarball.
# Re-run = update for the tarball case.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

if rpm -q discord >/dev/null 2>&1 || sudo dnf install -y discord 2>/dev/null; then
  sudo dnf upgrade -y discord || true
  ok "Discord from dnf."
  exit 0
fi

warn "Not packaged in the enabled repos; using the official tarball."
dl="https://discord.com/api/download?platform=linux&format=tar.gz"
final="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$dl")"
latest="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"$final" | head -1 || true)"
cur="$(cat /opt/discord/.version 2>/dev/null || true)"
if [ -n "$latest" ] && [ "$latest" = "$cur" ]; then ok "Discord $cur is current."; exit 0; fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$final" -o "$tmp/discord.tar.gz"
tar -xzf "$tmp/discord.tar.gz" -C "$tmp"
sudo rm -rf /opt/discord
sudo mv "$tmp/Discord" /opt/discord
echo "${latest:-unknown}" | sudo tee /opt/discord/.version >/dev/null
sudo ln -sf /opt/discord/Discord /usr/local/bin/discord
sudo tee /usr/share/applications/discord.desktop >/dev/null <<'DESK'
[Desktop Entry]
Name=Discord
Comment=Voice and text chat
Exec=/opt/discord/Discord %U
Icon=/opt/discord/discord.png
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=discord
DESK
ok "Discord ${latest:-?} installed to /opt/discord."
