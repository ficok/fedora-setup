# CLI tools cheat sheet

| Tool | Use | Example |
|---|---|---|
| `lf` | terminal file manager (`q` quit, `space` select, `d`/`y`/`p` cut/copy/paste) | `lf ~/Documents` |
| `rofi` | launcher / dmenu / window switcher | `rofi -show drun`, `printf 'a\nb' \| rofi -dmenu` |
| `swaymsg` | talk to sway | `swaymsg -t get_outputs`, `swaymsg reload` |
| `eww` | status bars | `eww reload`, `eww open topbar`, `eww logs` |
| `swaylock` / `swayidle` | lock screen / idle actions (timeouts at top of sway config) | `swaylock -f` |
| `grim` + `slurp` | screenshots | `grim -g "$(slurp)" out.png` |
| `wl-copy` / `wl-paste` | clipboard from the shell | `cat f \| wl-copy` |
| `brightnessctl` | screen brightness | `brightnessctl set 10%+` |
| `wpctl` | volume (PipeWire) | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` |
| `nmtui` | Wi-Fi / network menu | `nmtui` |
| `bluetoothctl` / `blueman-manager` | Bluetooth | `bluetoothctl connect <MAC>` |
| `fzf` | fuzzy finder (`Ctrl+R` history) | `vim $(fzf)` |
| `rg` / `fd` / `bat` | fast grep / find / cat with syntax colors | `rg TODO`, `fd '\.cpp$'`, `bat f` |
| `btop` | system monitor | `btop` |
| `xprop` / `xev` | inspect X11 (Xwayland) windows / events | `xprop WM_CLASS` |
| `journalctl` | logs | `journalctl -b -u greetd` |
| `dnf` | packages | `sudo dnf upgrade`, `dnf search x` |
