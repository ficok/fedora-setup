# One session, everything working

There is exactly one session entry, `/usr/share/wayland-sessions/swayfx.desktop`, which runs
`~/.local/bin/swayfx-session`. Nothing is nested or wrapped a second time. What makes it work:

1. **Environment from the shell.** `swayfx-session` exports the session variables, then runs
   `$SHELL -l -c 'exec sway'`. The *login* shell reads `~/.zprofile` (PATH with `~/.scripts` and
   `~/.local/bin`, etc.) and then replaces itself with sway. Every program sway starts inherits
   that environment, so no per-program fixes are needed.
2. **rofi + scripts.** rofi is started by a sway keybind, so it inherits the PATH above; `powermenu` and any
   script in `~/.scripts` are found by name.
3. **eww bars.** Started from sway (`exec eww open-many ...`), so they inherit `WAYLAND_DISPLAY` and
   `SWAYSOCK`; the workspace module's `swaymsg` calls therefore work. eww scripts use absolute paths.
4. **Wallpaper.** Handled by sway itself (`output * bg ...`, which spawns swaybg with the right env).
5. **Services that don't inherit from sway** (portals, anything started by systemd/D-Bus) get the variables
   from `dbus-update-activation-environment --systemd ...` in the sway config.
6. **NVIDIA**: `--unsupported-gpu` and `WLR_NO_HARDWARE_CURSORS=1` in the session script,
   `nvidia-drm.modeset=1` set by `install.sh`.
7. **Greeter** (greetd + ReGreet in `cage`) needs `accountsservice` (enabled via systemctl) to list users.

Why edits in `~/.config` changed `linux-setup/dotfiles/` last time: most likely the old script symlinked the
config into the repo, so both paths were the same files. This time they are plain copies.
