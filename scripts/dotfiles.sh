#!/usr/bin/env bash
# Symlinks dotfiles/ into $HOME (existing files are moved to *.bak.<timestamp>, never deleted).
# Because they are symlinks, editing a file in this repo edits your live config.
set -euo pipefail
. "$(dirname "$0")/../lib/common.sh"

link() { # source target
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then return 0; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    warn "Backed up existing $dst"
  fi
  ln -s "$src" "$dst"
  ok "linked $dst"
}

D="$ROOT_DIR/dotfiles"
chmod +x "$D"/eww/scripts/* "$D"/bin/* "$D"/lf/preview "$D"/lf/cleaner

for d in sway swaylock eww kitty lf mako rofi; do link "$D/$d" "$HOME/.config/$d"; done
link "$D/zsh/zshrc" "$HOME/.zshrc"
for b in "$D"/bin/*; do link "$b" "$HOME/.local/bin/$(basename "$b")"; done

xdg-user-dirs-update 2>/dev/null || true

if have sway; then
  if sway -C -c "$D/sway/config" >/dev/null 2>&1; then ok "sway config validated"
  else warn "'sway -C' reported problems (or could not run here); check after first login: sway -C"; fi
fi
