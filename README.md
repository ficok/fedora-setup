# Linux setup: Fedora + Sway + eww

A minimal Fedora install turned into a tiling Wayland desktop by one unattended script.
Re-running it updates everything that does not update itself.

- **Compositor:** Sway (i3-compatible, your i3 config is ported, see section 6)
- **Bars:** eww, a top and a bottom bar, fully scriptable (`dotfiles/eww/`)
- **Launcher:** rofi (Wayland build) with fuzzel as automatic fallback
- **Wallpaper:** sway's built-in background through the `wallpaper` helper (replaces nitrogen)
- **Login screen:** greetd + ReGreet (GTK4, styled with CSS)
- **Lock / idle:** swaylock + swayidle (timeouts are two variables at the top of `dotfiles/sway/config`)
- **Shell and files:** zsh + oh-my-zsh, lf (terminal), Thunar (GUI), kitty terminal
- **Apps:** VS Code, Brave, Discord, Obsidian, plus the dev toolchain (git, clang, cmake, LLVM headers, ...)
- **NVIDIA** driver with **Secure Boot kept on** (key enrollment is automated, see below)

Tool usage guide: [CLI-TOOLS.md](CLI-TOOLS.md)

---

## 1. Before you start

1. **Secure Boot stays ON** (you need it for Vanguard). Nothing to change in the firmware.
2. **Unplug the Windows SSD** so the Fedora installer cannot touch it. Plug it back in after the install; boot Windows from the firmware boot menu (usually F11/F12), or let GRUB chainload it.
3. **Any current Fedora release works.** Sway is in Fedora's own repos, so there is no COPR to wait for. The only third-party repo is RPM Fusion (NVIDIA driver, and Discord if packaged there).
4. Download the **Fedora Everything netinstall ISO**, write it to a USB stick, boot it.
5. In the installer (Anaconda):
   - Software selection: **Minimal Install** (nothing else ticked)
   - Install destination: **only the Linux SSD**
   - User: create your user and tick **Make this user administrator**
   - Network: connect Ethernet/Wi-Fi so the installer and the script can download

## 2. Install

After the first boot into the text console, log in as your user and run:

```bash
sudo dnf install -y git        # the one thing a minimal install lacks
git clone <wherever you keep this repo> ~/linux-setup
cd ~/linux-setup
./install.sh
```

It asks for your sudo password **once**, then runs unattended (30 to 60 minutes: ReGreet and possibly eww are compiled from source). Go do something else. At the end it prints a summary of anything that failed and any manual step.

Options: `--skip-upgrade`, `--no-nvidia`, `--update` (see section 5).

## 3. First reboot: Secure Boot key enrollment

Because Secure Boot is on, the NVIDIA kernel module has to be signed with a key you enroll once. The script generates the key and schedules the enrollment. On the first reboot a **blue "Perform MOK management" screen** appears before Fedora starts (you have about 10 seconds to press a key):

1. **Enroll MOK**, then **Continue**, then **Yes**
2. Enter the one-time password the script printed (also in `~/.local/state/linux-setup/mok-password.txt`)
3. **Reboot**

Windows is unaffected; this only adds a key to the shim that Fedora boots through. From then on `akmods` signs a new NVIDIA module after every kernel update automatically.

Then the greeter appears. Pick **Sway (linux-setup)** (not plain "Sway": the wrapper sets the Wayland environment and the NVIDIA flag) and log in.

## 4. Where things live

| What | Where |
|---|---|
| Package lists (add lines freely) | `packages/*.txt`, one package per line, `#` comments |
| Third-party repos, NVIDIA, services | `scripts/repos.sh`, `scripts/nvidia.sh`, `scripts/system.sh` |
| One script per program (all re-runnable) | `scripts/programs/NN-name.sh`, run in filename order |
| Your configs (symlinked into `~`) | `dotfiles/` |
| Fonts to install (git repos / zip URLs) | `fonts.list` |
| Logs, MOK password, missing-package report | `~/.local/state/linux-setup/` |

To add a program: drop a `scripts/programs/NN-name.sh` that sources `lib/common.sh` (copy any existing one). To add packages: append to a `packages/*.txt`. Nothing else needs editing.

**Dotfiles are symlinks into this repo**, so editing `~/.config/sway/keybindings.conf` edits the repo copy (commit it). Existing files are moved to `*.bak.<timestamp>`, never deleted.

**Fonts:** your private font repo goes in `fonts.list` as `git git@github.com:you/fonts.git` (needs an SSH key without a passphrase, because the script must not prompt), or just copy the files into `~/.local/share/fonts/` and run `fc-cache -f`. Then set the name in `dotfiles/kitty/font.conf`, and in `dotfiles/eww/eww.scss`. The default eww bar uses plain text labels instead of icons so it looks right before your Nerd Font is installed.

## 5. Updating

```bash
./install.sh --update
```

This runs `dnf upgrade` (which also updates Sway, VS Code, Brave, Discord if it came from RPM Fusion) and re-runs every program script. Each one checks the latest version first and only downloads when something is newer: lf, Obsidian, the Discord tarball (if used), ReGreet and eww (if built from source), plus `git pull` for oh-my-zsh and its plugins.

## 6. Sway and your ported i3 config

Config lives in `~/.config/sway/` with your original split (`config`, `autostart.conf`, `app_shortcuts.conf`, `scratchpad.conf`, `window_constraints.conf`, `keybindings.conf`) plus a new `wayland.conf` for what X11 tools did in i3. The mod key is still Alt. Reload with `Alt+Shift+C`, validate with `sway -C`.

**Not ported yet (you did not paste them):** `scratchpad.conf` and `window_constraints.conf` (empty stubs), your Xresources colors (Catppuccin placeholders in `config`), your polybar modules (eww has its own starter bars), your rofi `launcher.rasi` (placeholder theme), the `switch_to_*` monitor scripts and `autostart.sh`.

| i3 | Sway |
|---|---|
| `set_from_resource` | plain `set` colors; variables moved above the `include` lines, because sway reads includes in place |
| `bindsym ograve` | `bindcode 47`: the same physical key in every layout (`ograve` exists only in the Italian layout) |
| `pactl ... sink 0`, `xbacklight` | `wpctl` on the default device, `brightnessctl` |
| `restart` | `reload` (sway has no restart) |
| `i3-nagbar` | `swaynag` |
| `setxkbmap us / rs` | `xkb_switch_layout` over `us`, Serbian latin, Serbian cyrillic (same F11/F12 keys) |
| nitrogen, polybar, picom, pulseaudio | `wallpaper` helper, eww bars, nothing (sway composites itself), PipeWire |
| `exec source ~/.zshrc` | `~/.config/sway/env`, loaded by the session wrapper, which is what sets PATH |
| `switch_to_*` (xrandr) | `switch-display` helper: `switch-display '^HDMI'`, `switch-display all` |
| `exec --no-startup-id` | dropped (sway ignores the flag) |

**Added:** `Alt+Escape` lock, `Print` screenshot, `Alt+Shift+V` clipboard history, `Alt+Shift+B` eww reload, media keys. Lock and screen-off timers are the two `set` variables at the top of `config`.

**Rounded corners:** upstream sway does not have them. SwayFX adds them, but on Fedora it comes from a COPR, which is the dependency this setup avoids.

**NVIDIA:** sway refuses proprietary drivers unless started with `--unsupported-gpu`. The login entry **Sway (linux-setup)** runs `/usr/local/bin/sway-session`, which adds the flag only when the NVIDIA module is loaded.

## 7. eww in ten lines

- `dotfiles/eww/eww.yuck` defines **data sources** (`deflisten` for event-driven scripts, `defpoll` for periodic commands), **widgets** (`defwidget`) and **windows** (`defwindow`: one per bar or popup).
- `dotfiles/eww/eww.scss` styles everything (GTK CSS in SCSS syntax).
- Modules are just widgets: reorder or remove them by editing the bar's `centerbox` (left / center / right).
- Click actions are widget properties: `:onclick`, `:onrightclick`, `:onmiddleclick`, `:onscroll`. The clock toggles a calendar popup, the volume module opens the mixer / mutes / scrolls.
- A custom module = a script in `dotfiles/eww/scripts/` + a `defpoll`/`deflisten` + a widget that shows the value.
- Reload after edits: `Alt+Shift+B`. Debug: `eww logs`, `eww state`, `eww inspector`.
- Top bar includes a system tray (needed by `nm-applet` and `blueman`).
- I have not checked how actively eww itself is maintained; if it stops fitting, Ironbar and Quickshell are the usual alternatives and the same compositor config works.

## 8. Troubleshooting

| Symptom | What to do |
|---|---|
| Black screen / no greeter on first boot | Wait ~5 min (NVIDIA module may be building). Otherwise Ctrl+Alt+F3, log in, `sudo akmods --force`, `sudo systemctl restart greetd`. |
| Greeter loops or is missing | Ctrl+Alt+F3, log in, run `sway-session` directly. Greeter logs: `journalctl -u greetd -b`. Disable it with `sudo systemctl disable greetd`. |
| `nvidia` module will not load | `mokutil --sb-state`, `mokutil --test-key /etc/pki/akmods/certs/public_key.der` (must say *already enrolled*), `modinfo -F signer nvidia`. If the key is not enrolled: `sudo mokutil --import /etc/pki/akmods/certs/public_key.der`, reboot, finish the blue screen. |
| SELinux suspected | `sudo ausearch -m avc -ts recent` to see denials. |
| A package failed to install | The summary lists it; check the name with `dnf search`, fix it in `packages/*.txt`, re-run `./install.sh --skip-upgrade`. |
| Brave not crisp / blurry | `brave://flags/#ozone-platform-hint` → *Auto* or *Wayland*. |
| Sway refuses to start on NVIDIA | Start it through `sway-session` (or the **Sway (linux-setup)** login entry); it adds `--unsupported-gpu` when the driver is loaded. |

**Honest status:** this repo was written without access to a Fedora machine. Every script passes `bash -n` and shellcheck, and the jq filters and `switch-display` were run against sample data (the sway config could not be validated with `sway -C` here), but the dnf steps, package names and the RPM Fusion setup have not been exercised end to end. Expect to fix a package name or two on the first run; the summary and the log are designed to make that quick, and every step is re-runnable.
