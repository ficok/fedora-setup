#!/usr/bin/env bash
# Third-party dnf repositories that everything else depends on (only RPM Fusion; Sway is in Fedora itself).
set -euo pipefail
. "$(dirname "$0")/../lib/common.sh"
VER="$(fedora_version)"

sudo dnf install -y dnf-plugins-core curl

# --- RPM Fusion (NVIDIA driver, and Discord if packaged there) ---
if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
  for kind in free nonfree; do   # import keys first so signature verification passes
    sudo rpm --import "/usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-${kind}-fedora-${VER}" 2>/dev/null || true
  done
  urls=("https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${VER}.noarch.rpm"
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${VER}.noarch.rpm")
  sudo dnf install -y "${urls[@]}" \
    || sudo dnf install -y --setopt=localpkg_gpgcheck=0 "${urls[@]}"   # release rpms only contain repo files
fi

sudo dnf makecache -y
