#!/usr/bin/env bash
# Fedora minimal -> Sway desktop. Asks for the sudo password once, then runs unattended.
#
#   ./install.sh                 full install
#   ./install.sh --update        upgrade dnf packages and re-run every program script
#   ./install.sh --skip-upgrade  skip the initial `dnf upgrade`
#   ./install.sh --no-nvidia     skip the NVIDIA driver / Secure Boot key step
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

UPDATE=0 SKIP_UPGRADE=0 NO_NVIDIA=0
for a in "$@"; do
  case "$a" in
    --update) UPDATE=1 ;;
    --skip-upgrade) SKIP_UPGRADE=1 ;;
    --no-nvidia) NO_NVIDIA=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) die "unknown option: $a" ;;
  esac
done

LOG="$STATE_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
log "Logging to $LOG"

[ "$(id -u)" -ne 0 ] || die "Run as your normal user, not root (the script uses sudo where needed)."
[ -r /etc/os-release ] && . /etc/os-release
[ "${ID:-}" = fedora ] || die "This installer targets Fedora (found: ${ID:-unknown})."
[ -d /sys/firmware/efi ] || warn "Not booted in UEFI mode; Secure Boot steps will be skipped."

# ---- the one and only password prompt --------------------------------------------------
log "Asking for sudo once; nothing else will prompt after this."
sudo -v || die "sudo authentication failed."
( while true; do sudo -n true 2>/dev/null; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
KEEPALIVE=$!
trap 'kill "$KEEPALIVE" 2>/dev/null' EXIT

FAILED=()
run_step() { # name cmd...
  local name="$1"; shift
  log "==> $name"
  if "$@"; then ok "$name: done"; else warn "$name: FAILED (see log)"; FAILED+=("$name"); fi
}

if [ "$UPDATE" -eq 1 ]; then
  run_step "dnf upgrade" sudo dnf upgrade -y --refresh
else
  run_step "repos (RPM Fusion)" bash "$ROOT_DIR/scripts/repos.sh"
  [ "$SKIP_UPGRADE" -eq 1 ] || run_step "dnf upgrade" sudo dnf upgrade -y --refresh
  run_step "packages" bash "$ROOT_DIR/scripts/packages.sh"
  [ "$NO_NVIDIA" -eq 1 ] || run_step "nvidia + Secure Boot key" bash "$ROOT_DIR/scripts/nvidia.sh"
  run_step "system services + sway session" bash "$ROOT_DIR/scripts/system.sh"
fi

for s in "$ROOT_DIR"/scripts/programs/*.sh; do
  [ -e "$s" ] || continue
  run_step "program: $(basename "$s" .sh)" bash "$s"
done

[ "$UPDATE" -eq 1 ] || run_step "dotfiles" bash "$ROOT_DIR/scripts/dotfiles.sh"

# ---- summary ---------------------------------------------------------------------------
echo
echo "=================== SUMMARY ==================="
if [ "${#FAILED[@]}" -eq 0 ]; then ok "Every step succeeded."; else
  warn "Failed steps:"; printf '   - %s\n' "${FAILED[@]}"
fi
if [ -s "$STATE_DIR/missing-packages.txt" ]; then
  warn "Packages not found in any enabled repo:"; sed 's/^/   - /' "$STATE_DIR/missing-packages.txt"
fi
if [ -s "$STATE_DIR/post-install.txt" ]; then echo; cat "$STATE_DIR/post-install.txt"; fi
echo "Full log: $LOG"
[ "$UPDATE" -eq 1 ] || echo "Reboot when ready:  sudo reboot"
[ "${#FAILED[@]}" -eq 0 ]
