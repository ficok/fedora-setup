#!/usr/bin/env bash
# Visual Studio Code from Microsoft's own dnf repo (so `dnf upgrade` updates it).
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
sudo dnf install -y code
ok "VS Code installed/updated."
