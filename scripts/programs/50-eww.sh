#!/usr/bin/env bash
# eww (widgets/status bar). Uses the COPR package when it exists, otherwise builds from git.
# Re-run = update (dnf upgrade covers the package; a source build is pulled and rebuilt).
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

if sudo dnf install -y eww 2>/dev/null; then
  ok "eww installed from dnf."
  exit 0
fi

warn "No eww package for this release; building from source (takes a few minutes)."
dnf_install gcc rust cargo gtk3-devel gtk-layer-shell-devel pango-devel \
            gdk-pixbuf2-devel libdbusmenu-gtk3-devel cairo-devel glib2-devel

src="$HOME/.local/src/eww"
before=""; [ -d "$src/.git" ] && before="$(git -C "$src" rev-parse HEAD)"
git_sync https://github.com/elkowar/eww.git "$src"
after="$(git -C "$src" rev-parse HEAD)"

if [ "$before" = "$after" ] && [ -x "$HOME/.local/bin/eww" ]; then ok "eww already current."; exit 0; fi
( cd "$src" && cargo build --release --no-default-features --features=wayland )
install -Dm755 "$src/target/release/eww" "$HOME/.local/bin/eww"
ok "eww built and installed to ~/.local/bin/eww."
