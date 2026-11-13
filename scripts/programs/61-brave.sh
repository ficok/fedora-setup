#!/usr/bin/env bash
# Brave from Brave's own dnf repo (so `dnf upgrade` updates it).
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo curl -fsSL -o /etc/yum.repos.d/brave-browser.repo \
  https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo dnf install -y brave-browser
ok "Brave installed/updated."
