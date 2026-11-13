#!/usr/bin/env bash
# Login screen: greetd + ReGreet (GTK4, themable with CSS) running inside the `cage` kiosk compositor.
# ReGreet is not in Fedora: try dnf, else build the latest release with cargo. gtkgreet is the fallback.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

dnf_install greetd cage
sudo dnf install -y --skip-unavailable gtkgreet

greeter=""
if have regreet || sudo dnf install -y regreet 2>/dev/null; then
  greeter=regreet
else
  json="$(gh_latest rharish101/ReGreet || true)"
  tag="$(jq -r '.tag_name // empty' <<<"$json" 2>/dev/null || true)"
  if [ -n "$tag" ]; then
    if [ "$(cat "$STATE_DIR/regreet-version" 2>/dev/null || true)" != "$tag" ] || [ ! -x /usr/local/bin/regreet ]; then
      log "Building ReGreet $tag (a few minutes)"
      dnf_install gcc rust cargo gtk4-devel pkgconf-pkg-config
      tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
      if cargo install --locked --git https://github.com/rharish101/ReGreet --tag "$tag" --root "$tmp/root"; then
        sudo install -Dm755 "$tmp/root/bin/regreet" /usr/local/bin/regreet
        echo "$tag" > "$STATE_DIR/regreet-version"
      else
        warn "ReGreet build failed."
      fi
    fi
    if [ -x /usr/local/bin/regreet ]; then greeter=regreet; fi
  fi
fi
if [ -z "$greeter" ] && have gtkgreet; then greeter=gtkgreet; fi
[ -n "$greeter" ] || die "No greeter available (regreet and gtkgreet both failed)."
log "Using greeter: $greeter"

# Which user does this greetd package run the greeter as?
guser=greeter; id -u greetd >/dev/null 2>&1 && guser=greetd

sudo install -d -m 0755 /etc/greetd
if [ "$greeter" = regreet ]; then
  sudo install -d -o "$guser" -g "$guser" -m 0755 /var/lib/regreet /var/log/regreet /var/cache/regreet
  sudo install -m 0644 "$ROOT_DIR/dotfiles/greetd/regreet.toml" /etc/greetd/regreet.toml
  sudo install -m 0644 "$ROOT_DIR/dotfiles/greetd/regreet.css"  /etc/greetd/regreet.css
  cmd='env WLR_NO_HARDWARE_CURSORS=1 cage -s -m last -- regreet'
else
  sudo install -m 0644 "$ROOT_DIR/dotfiles/greetd/regreet.css" /etc/greetd/gtkgreet.css
  cmd='env WLR_NO_HARDWARE_CURSORS=1 cage -s -m last -- gtkgreet -l -s /etc/greetd/gtkgreet.css'
fi

sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
command = "$cmd"
user = "$guser"
TOML

sudo systemctl enable greetd.service
ok "greetd enabled (starts at next boot). Choose 'Sway (linux-setup)' on the login screen."
