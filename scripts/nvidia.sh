#!/usr/bin/env bash
# NVIDIA proprietary driver (RPM Fusion) + Secure Boot key enrollment (MOK).
set -euo pipefail
. "$(dirname "$0")/../lib/common.sh"

# NVIDIA's PCI vendor id is 0x10de. No NVIDIA GPU (e.g. a laptop with Intel/AMD graphics): nothing to do.
if ! grep -qs 0x10de /sys/bus/pci/devices/*/vendor; then
  log "No NVIDIA GPU detected; skipping driver and Secure Boot key steps."
  exit 0
fi

dnf_install akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo dnf install -y --skip-unavailable libva-nvidia-driver

printf 'options nvidia-drm modeset=1\n' | sudo tee /etc/modprobe.d/nvidia-drm.conf >/dev/null

NOTE="$STATE_DIR/post-install.txt"
: > "$NOTE"

if [ -d /sys/firmware/efi ] && secure_boot_enabled; then
  log "Secure Boot is ON: the NVIDIA module must be signed with your own key."
  dnf_install kmodtool akmods mokutil openssl
  KEY=/etc/pki/akmods/certs/public_key.der
  [ -f "$KEY" ] || sudo kmodgenkey -w

  if sudo mokutil --test-key "$KEY" 2>&1 | grep -q 'already enrolled'; then
    ok "Signing key already enrolled."
  elif sudo mokutil --list-new 2>&1 | grep -qi 'is empty'; then
    pw="$(shuf -i 10000000-99999999 -n1)"          # digits only: safe on the firmware keyboard
    hf="$(mktemp)"; openssl passwd -6 "$pw" > "$hf"
    sudo mokutil --import "$KEY" --hash-file "$hf"
    rm -f "$hf"
    ( umask 077; printf '%s\n' "$pw" > "$STATE_DIR/mok-password.txt" )
    cat >> "$NOTE" <<EOT
>>> ACTION REQUIRED ON THE FIRST REBOOT (Secure Boot key enrollment) <<<
A blue "Perform MOK management" screen appears before Fedora starts. You have ~10 s to press a key.
  1. Enroll MOK  ->  Continue  ->  Yes
  2. Password: $pw        (also saved in $STATE_DIR/mok-password.txt)
  3. Reboot
If you miss the screen, run:  sudo mokutil --import $KEY   and reboot again.
EOT
  else
    ok "A key enrollment is already pending from an earlier run; reusing its password."
    if [ -f "$STATE_DIR/mok-password.txt" ]; then
      echo "Pending MOK enrollment password: $(cat "$STATE_DIR/mok-password.txt")  (Enroll MOK -> Continue -> Yes -> password -> Reboot)" >> "$NOTE"
    fi
  fi
else
  log "Secure Boot is off or not in use; no key enrollment needed."
fi

# Build the module now so the first boot already has it (otherwise akmods builds it at boot).
newest="$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -1)"
sudo dnf install -y --skip-unavailable "kernel-devel-$newest" || true
sudo akmods --force --kernels "$newest" || warn "akmods build failed; it will retry at boot (wait ~5 min at first boot, or run: sudo akmods --force)"
sudo dracut -f --regenerate-all || true
echo "If the screen stays black on first boot, wait ~5 minutes, or switch to a TTY (Ctrl+Alt+F3) and run: sudo akmods --force" >> "$NOTE"
