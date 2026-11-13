#!/usr/bin/env bash
# Shared helpers. Sourced by install.sh and by every script under scripts/.

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/linux-setup"
mkdir -p "$STATE_DIR" "$HOME/.local/bin"

# Never let a tool stop and wait for input.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
export CARGO_TERM_COLOR=never
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

fedora_version() { ( . /etc/os-release; echo "$VERSION_ID" ); }

# Installs what exists, silently skips what doesn't (the caller verifies afterwards).
dnf_install_lenient() { sudo dnf install -y --skip-unavailable "$@"; }
# Installs everything or fails.
dnf_install() { sudo dnf install -y "$@"; }

# cpu architecture names as used by most GitHub release assets
arch_go() { case "$(uname -m)" in x86_64) echo amd64 ;; aarch64) echo arm64 ;; *) uname -m ;; esac; }

# Latest GitHub release JSON for owner/repo
gh_latest() {
  curl -fsSL -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/$1/releases/latest"
}

# Clone if missing, fast-forward if present.
git_sync() { # url dir
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only --quiet
  else
    mkdir -p "$(dirname "$dir")"
    git clone --depth=1 --quiet "$url" "$dir"
  fi
}

secure_boot_enabled() {
  local f
  f=$(ls /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | head -1)
  [ -n "$f" ] && [ "$(od -An -t u1 -j4 -N1 "$f" 2>/dev/null | tr -d ' ')" = "1" ]
}
