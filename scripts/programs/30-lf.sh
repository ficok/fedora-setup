#!/usr/bin/env bash
# lf file manager: latest GitHub release binary into ~/.local/bin. Re-run = update.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

json="$(gh_latest gokcehan/lf)"
tag="$(jq -r .tag_name <<<"$json")"
cur="$(lf -version 2>/dev/null || echo none)"
if [ "$cur" = "$tag" ]; then ok "lf $tag already installed."; exit 0; fi

asset="lf-linux-$(arch_go).tar.gz"
url="$(jq -r --arg a "$asset" '.assets[] | select(.name==$a) | .browser_download_url' <<<"$json")"
[ -n "$url" ] || die "No $asset in release $tag"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp/lf.tgz"
tar -xzf "$tmp/lf.tgz" -C "$tmp"
install -Dm755 "$tmp/lf" "$HOME/.local/bin/lf"
ok "lf $tag installed."
