#!/usr/bin/env bash
# Obsidian: official AppImage from GitHub releases (there is no RPM). Re-run = update.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

dir="$HOME/.local/opt/obsidian"
json="$(gh_latest obsidianmd/obsidian-releases)"
tag="$(jq -r .tag_name <<<"$json")"
if [ "$(cat "$dir/VERSION" 2>/dev/null || true)" = "$tag" ] && [ -x "$dir/Obsidian.AppImage" ]; then
  ok "Obsidian $tag is current."; exit 0
fi

url="$(jq -r '.assets[] | select(.name|test("^Obsidian-[0-9.]+\\.AppImage$")) | .browser_download_url' <<<"$json" | head -1)"
[ -n "$url" ] || die "No x86_64 AppImage in release $tag"

mkdir -p "$dir" "$HOME/.local/share/applications" "$HOME/.local/share/icons"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fSL "$url" -o "$tmp/Obsidian.AppImage"
chmod +x "$tmp/Obsidian.AppImage"
( cd "$tmp" && ./Obsidian.AppImage --appimage-extract 'usr/share/icons/hicolor/512x512/apps/obsidian.png' >/dev/null 2>&1 ) || true
[ -f "$tmp/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png" ] \
  && cp "$tmp/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png" "$HOME/.local/share/icons/obsidian.png"
mv -f "$tmp/Obsidian.AppImage" "$dir/Obsidian.AppImage"
echo "$tag" > "$dir/VERSION"

cat > "$HOME/.local/share/applications/obsidian.desktop" <<DESK
[Desktop Entry]
Name=Obsidian
Comment=Knowledge base
Exec=$dir/Obsidian.AppImage --ozone-platform-hint=auto %U
Icon=$HOME/.local/share/icons/obsidian.png
Terminal=false
Type=Application
Categories=Office;
MimeType=x-scheme-handler/obsidian;
DESK
ln -sf "$dir/Obsidian.AppImage" "$HOME/.local/bin/obsidian"
ok "Obsidian $tag installed."
