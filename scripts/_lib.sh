# Shared helpers, sourced by install_* scripts (not run directly).
set -euo pipefail
BIN="$HOME/.local/bin"; OPT="$HOME/.local/opt"; SRC="$HOME/.local/src"; APPS="$HOME/.local/share/applications"
mkdir -p "$BIN" "$OPT" "$SRC" "$APPS"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

fetch() { curl -fL --progress-bar -o "$2" "$1"; }                     # fetch <url> <dest>
gh_asset() {                                                         # gh_asset <owner/repo> <regex> -> asset url
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    jq -r --arg re "$2" '[.assets[].browser_download_url | select(test($re))][0] // empty'
}
git_sync() { if [ -d "$2/.git" ]; then git -C "$2" pull -q --ff-only; else git clone -q "$1" "$2"; fi; }
latest_tag() {                                                       # latest_tag <git url> <series regex, e.g. 0\.20>
  git ls-remote --tags --refs "$1" | sed 's|.*refs/tags/||' | grep -E "^v?$2([.][0-9]+)*$" | sort -V | tail -1
}
# install_bundle <name> <extracted dir> <exe inside dir> [flags] [command name]
# Moves the app into ~/.local/opt/<name> and drops a small launcher script (not a symlink) in ~/.local/bin.
install_bundle() {
  local name=$1 dir=$2 exe=$3 flags=${4:-} cmd=${5:-$1}
  rm -rf "$OPT/$name"; mv "$dir" "$OPT/$name"
  printf '#!/bin/sh\nexec "%s/%s" %s "$@"\n' "$OPT/$name" "$exe" "$flags" > "$BIN/$cmd"
  chmod +x "$BIN/$cmd"
}
desktop_entry() {                                                    # desktop_entry <cmd> <Display Name> <icon>
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s/%s %%U\nIcon=%s\nCategories=Utility;\n' \
    "$2" "$BIN" "$1" "$3" > "$APPS/$1.desktop"
}
