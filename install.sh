#!/usr/bin/env bash
# Single-use Fedora setup. Run once as your normal user: ./install.sh
# Later updates are done with the per-program scripts in ~/.scripts (install_discord, install_swayfx, ...).
set -euo pipefail
cd "$(dirname "$0")"
DONE="$HOME/.local/state/linux-setup.done"
[ "$EUID" -ne 0 ] || { echo "Run as your normal user, not root."; exit 1; }
[ ! -e "$DONE" ] || { echo "Already ran on $(cat "$DONE"). This script is single-use."; exit 1; }

# sudo password once; keep the ticket alive until this script exits
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &

source scripts/_lib.sh
log() { printf '\n==> %s\n' "$*"; }

log "RPM Fusion"
F=$(rpm -E %fedora)
sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$F.noarch.rpm" \
                    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$F.noarch.rpm"

log "Packages"
mapfile -t PKGS < <(sed 's/#.*//' packages.txt | tr -s ' \t' '\n' | grep .)
sudo dnf install -y --skip-unavailable "${PKGS[@]}"
sudo dnf install -y rofi-wayland || sudo dnf install -y rofi   # newer Fedora ships Wayland support in plain rofi
missing=(); for p in "${PKGS[@]}"; do rpm -q --quiet --whatprovides "$p" || missing+=("$p"); done
[ ${#missing[@]} -eq 0 ] || { echo "Not installed: ${missing[*]}"; echo "Fix packages.txt and re-run."; exit 1; }

log "NVIDIA driver (signed with a local key for Secure Boot)"
[ -f /etc/pki/akmods/certs/public_key.der ] || sudo kmodgenca -a
sudo dnf install -y akmod-nvidia
sudo akmods --force || echo "akmods build failed; check 'journalctl -u akmods' after reboot"
sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"

log "Services"
sudo systemctl enable --now accounts-daemon.service bluetooth.service
sudo systemctl enable --force greetd.service
sudo systemctl set-default graphical.target
sudo usermod -aG video greetd

log "ReGreet (greeter) from source"
tag=$(latest_tag https://github.com/rharish101/ReGreet.git '[0-9]+\.[0-9]+')   # latest release tag
rm -rf "$SRC/regreet"; git clone -q --depth 1 --branch "$tag" https://github.com/rharish101/ReGreet.git "$SRC/regreet"
cargo build --release --manifest-path "$SRC/regreet/Cargo.toml"
sudo install -Dm755 "$SRC/regreet/target/release/regreet" /usr/local/bin/regreet
sudo install -d -o greetd -g greetd /var/lib/regreet /var/log/regreet
sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "env WLR_NO_HARDWARE_CURSORS=1 GTK_USE_PORTAL=0 GDK_DEBUG=no-portals cage -s -mlast -- regreet"
user = "greetd"
EOF
printf '[GTK]\napplication_prefer_dark_theme = true\n' | sudo tee /etc/greetd/regreet.toml >/dev/null
# style the greeter by adding CSS in /etc/greetd/regreet.css

log "Session entry"
sudo tee /usr/share/wayland-sessions/swayfx.desktop >/dev/null <<EOF
[Desktop Entry]
Name=SwayFX
Comment=SwayFX session
Exec=$HOME/.local/bin/swayfx-session
Type=Application
DesktopNames=sway;SwayFX
EOF

log "Scripts and dotfiles (copied, no symlinks)"
mkdir -p "$HOME/.scripts" "$HOME/Pictures"
cp -f scripts/* "$HOME/.scripts/" && chmod +x "$HOME"/.scripts/*
install -m755 session/swayfx-session "$HOME/.local/bin/swayfx-session"
cp -rT --backup=numbered dotfiles "$HOME"          # existing files are kept as *.~1~

failed=()
for s in install_swayfx install_eww install_lf install_ohmyzsh install_discord install_brave install_vscode install_obsidian; do
  log "$s"; "$HOME/.scripts/$s" || failed+=("$s")
done

mkdir -p "$(dirname "$DONE")"; date -Is > "$DONE"
echo
[ ${#failed[@]} -eq 0 ] || echo "These failed, re-run them from ~/.scripts once fixed: ${failed[*]}"
echo "Done. Now follow README.md step 4 (Secure Boot key) before rebooting."
