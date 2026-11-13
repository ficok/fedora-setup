# Fedora + SwayFX setup

## Install
1. Install Fedora (minimal / Everything netinstall, no desktop), Secure Boot **on**. Unplug the Windows SSD first.
2. Log in on the TTY, get online (`nmtui`), then `sudo dnf upgrade -y && reboot`.
3. Copy this folder over and run `./install.sh`. Enter the sudo password once; it runs unattended
   (SwayFX, wlroots, scenefx, eww and ReGreet are compiled, so expect a while).
   It is **single-use**; it refuses to run twice.
4. **Secure Boot key** (before rebooting):
   ```
   sudo mokutil --import /etc/pki/akmods/certs/public_key.der   # choose a one-time password
   sudo reboot
   ```
   On the blue MOK screen: *Enroll MOK* -> Continue -> Yes -> password -> Reboot.
   Afterwards `mokutil --sb-state` says enabled and `lsmod | grep nvidia` shows the driver.
5. The greeter appears; pick **SwayFX** (default) and log in.
6. Plug the Windows SSD back in. Put your wallpaper at `~/Pictures/wallpaper.jpg`.
   Fonts: copy to `~/.local/share/fonts/`, then `fc-cache -f`.

## Updating programs
Run the script of the program you want; each fetches the latest version:
`install_swayfx` (log out/in afterwards), `install_eww` (then `eww reload`), `install_discord`,
`install_brave`, `install_vscode`, `install_obsidian`, `install_lf`, `install_ohmyzsh`.
System packages: `sudo dnf upgrade`.

## Where things are
- Config: edit `~/.config/...` directly. It was **copied**, so this folder is no longer linked to anything.
- Scripts: `~/.scripts` (in PATH). Binaries: `~/.local/bin`. Bundled apps: `~/.local/opt`. Sources: `~/.local/src`.
- Idle lock / screen-off timeouts: variables at the top of `~/.config/sway/config`.
- Sway log: `~/.cache/sway.log`.

See `SESSION.md` (how the single session works) and `CLI-TOOLS.md`.
