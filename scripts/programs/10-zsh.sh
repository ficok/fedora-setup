#!/usr/bin/env bash
# zsh + make it the login shell of the current user (no password prompt: uses sudo).
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

dnf_install zsh
z="$(command -v zsh)"
grep -qx "$z" /etc/shells || echo "$z" | sudo tee -a /etc/shells >/dev/null
me="${USER:-$(id -un)}"
if [ "$(getent passwd "$me" | cut -d: -f7)" != "$z" ]; then
  sudo usermod -s "$z" "$me"
  ok "Login shell of $me is now $z (takes effect at next login)."
else
  ok "Login shell already zsh."
fi
