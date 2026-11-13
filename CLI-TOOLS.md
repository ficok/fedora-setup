# CLI tools guide

What each tool is for, when to reach for it, and the commands you will actually use.
Everything here is installed by `packages/*.txt` or `scripts/programs/`.

Contents: [fzf](#fzf) · [ripgrep](#ripgrep-rg) · [fd](#fd) · [bat](#bat) · [btop](#btop) · [jq](#jq) · [tree](#tree) · [zip, unzip, tar](#zip-unzip-and-tar) · [lf](#lf-terminal-file-manager) · [kitty](#kitty) · [zsh and oh-my-zsh](#zsh-and-oh-my-zsh) · [Wayland and desktop utilities](#wayland-and-desktop-utilities) · [Fedora basics](#fedora-basics-dnf-systemd)

---

## fzf

**What:** a fuzzy finder. It reads lines from stdin, lets you type a few letters to filter them interactively, and prints the line you pick. Anything that produces a list (files, git branches, processes, history) becomes a searchable menu.

**Shell keybindings** (active in zsh through `source <(fzf --zsh)`, added to your zshrc):

| Keys | Does |
|---|---|
| `Ctrl+R` | fuzzy-search your command history (the single most useful one) |
| `Ctrl+T` | pick files and paste their paths onto the command line |
| `Alt+C` | pick a directory and `cd` into it |

**Use it as a pipe:**

```bash
git branch | fzf                                  # pick a branch
git checkout "$(git branch --format='%(refname:short)' | fzf)"
ps aux | fzf | awk '{print $2}'                   # pick a process, print its PID
fzf --preview 'bat --color=always {}'             # file picker with a live preview
fzf -m                                            # multi-select with Tab, confirm with Enter
code "$(fzf)"                                     # open the chosen file in VS Code
```

Query syntax inside the prompt: `'exact`, `^prefix`, `suffix$`, `!not-this`, and `a | b` for either.

## ripgrep (`rg`)

**What:** a very fast recursive text search. It skips what you do not want to search: it honours `.gitignore`, ignores hidden files and binaries by default. It replaces `grep -r` in almost every situation.

```bash
rg 'TODO'                      # search the current directory tree
rg -i 'error'                  # case-insensitive
rg -w 'main'                   # whole word only
rg -F 'a.b(c)'                 # fixed string, no regex
rg 'pattern' -t cpp            # only C++ files (rg --type-list shows the types)
rg 'pattern' -g '*.md'         # only files matching a glob; -g '!build/**' excludes
rg -C 3 'pattern'              # 3 lines of context around each match
rg -l 'pattern'                # list only the names of matching files
rg -uu 'pattern'               # also search hidden and gitignored files
rg --files | rg 'config'       # search file NAMES
rg 'old' -r 'new'              # preview a replacement (prints it, never edits files)
```

## fd

**What:** a friendlier, faster `find`. Smart defaults (ignores `.git` and gitignored files, case-insensitive unless you type capitals), and a regex by default. The Fedora package is called `fd-find`, the command is `fd`.

```bash
fd config                      # every file/dir whose name matches "config"
fd -e md                       # by extension
fd -t d src                    # only directories (-t f files, -t l symlinks)
fd -H -I secret                # include hidden (-H) and ignored (-I) files
fd -g '*.log' /var/log         # glob instead of regex, in a given directory
fd -e log -x gzip              # run a command on every result (-x, parallel)
fd -e cpp -X wc -l             # one command with ALL results as arguments (-X)
```

## bat

**What:** `cat` with syntax highlighting, line numbers and git change markers, and it pages long output. When its output goes into a pipe it behaves exactly like `cat`, so aliasing `cat` to it is safe (not done by default; `alias cat=bat`).

```bash
bat file.cpp                   # highlighted, paged
bat -n file.cpp                # line numbers
bat -p file.cpp                # plain: no decorations
bat -r 10:20 file.cpp          # only lines 10 to 20
bat -l json                    # force a language (useful when reading stdin)
curl -s https://example.com/api | bat -l json
bat --list-themes              # then: bat --theme=<name>
command cat file               # the real cat, if you alias cat to bat
```

## btop

**What:** a full-screen system monitor: CPU per core, memory, disks, network and a process list you can act on. Start it with `btop`.

| Key | Does |
|---|---|
| `q` | quit |
| `Esc` | open the menu (options and help) |
| `f` | filter the process list by name |
| `t` | toggle tree view of processes |
| `k` | kill the selected process (asks for confirmation) |
| `1` `2` `3` `4` | toggle the CPU / memory / network / process boxes |

Use cases: finding what is eating CPU or RAM, watching a build, checking whether the machine is thermally or memory limited.

## jq

**What:** `sed`/`awk` for JSON. It parses, filters and reshapes JSON from files or pipes. Essential for anything that talks to an API (the install scripts in this repo use it to read GitHub releases).

```bash
jq . file.json                          # pretty-print
jq '.name' file.json                    # one field
jq -r '.name' file.json                 # -r: raw output, no quotes (use this in scripts)
jq '.items[].id' file.json              # every id in an array
jq '.items[] | select(.size > 100)' f   # filter
jq '[.items[] | {id, name}]' f          # reshape into new objects
jq -c '.[]' f                           # one compact JSON object per line
jq 'length' f                           # count elements
jq --arg who "$USER" '.owner = $who' f  # pass a shell variable in safely
curl -s https://api.github.com/repos/gokcehan/lf/releases/latest | jq -r .tag_name
swaymsg -t get_workspaces -r | jq -r '.[].name'   # works on sway's JSON output too
```

## tree

**What:** prints a directory as an indented tree. Good for understanding a project layout or pasting a structure into notes.

```bash
tree -L 2                      # limit depth
tree -a -L 2                   # include hidden files
tree -d                        # directories only
tree -I 'node_modules|.git|build'   # exclude patterns
tree -h --du                   # sizes
```

## zip, unzip and tar

```bash
unzip file.zip                 # extract here
unzip file.zip -d out/         # extract into a directory
unzip -l file.zip              # list contents without extracting
zip -r out.zip dir/            # create from a directory

tar -xf archive.tar.gz         # extract (compression is detected automatically)
tar -czf out.tar.gz dir/       # create a gzip tarball  (-J for xz: out.tar.xz)
tar -tf archive.tar.gz         # list contents
tar -xf archive.tar.gz -C out/ # extract into a directory
```



---

## lf (terminal file manager)

**What:** a keyboard-driven file manager in three columns (parent, current, preview). Fast for navigating, bulk copy/move, and previewing files. Launch with `lf`, or press **`Ctrl+O`** in zsh to start `lfcd`, which also changes your shell's directory to wherever you quit.

| Keys | Does |
|---|---|
| `h` `j` `k` `l` | up one dir / down / up / into dir or open file |
| `gg` `G` | first / last entry |
| `Space` | select the current item (and move down) |
| `v` | invert selection; `u` unselect all |
| `y` | copy ("yank") selected |
| `d` | cut selected |
| `p` | paste into the current directory |
| `c` | clear the copy/cut buffer |
| `r` | rename |
| `D` | move to trash (configured in `dotfiles/lf/lfrc`) |
| `a` | make a directory (configured in `lfrc`) |
| `o` | open with the default app (`xdg-open`) |
| `/` then `n` / `N` | search, next / previous match |
| `zh` | toggle hidden files |
| `sn` `ss` `st` | sort by name / size / time |
| `$` or `!` | run a shell command (`$` returns when done, `!` waits for a key) |
| `:` | lf command line |
| `q` | quit |

Previews: text through `bat`, images through kitty's graphics protocol (this only works inside kitty). Config lives in `~/.config/lf/`; add your own commands with `cmd name ${{ ... }}` and bind them with `map`.

## kitty

You are not expected to use all of it; these are the features that pay off most. Config: `~/.config/kitty/kitty.conf` (fonts in `font.conf`). Reload a running instance with `Ctrl+Shift+F5`; `Ctrl+Shift+F2` opens the config in your editor.

**Essentials**

| Keys | Does |
|---|---|
| `Ctrl+Shift+C` / `V` | copy / paste |
| `Ctrl+Shift+T` | new tab in the current directory (customized) |
| `Ctrl+Shift+Left` / `Right` | previous / next tab |
| `Ctrl+Shift+Q` | close tab; `Ctrl+Shift+W` closes the window |
| `Ctrl+Shift+H` | open the scrollback in a pager (search it with `/`) |
| `Ctrl+Shift+=` / `-` | bigger / smaller font; `Ctrl+Shift+Backspace` resets |
| `Ctrl+Shift+E` | highlight URLs on screen and open one by typing its hint |
| `Ctrl+Shift+P` then `F` | highlight file paths on screen and insert one |

**Splits** (customized in `kitty.conf`; kitty's own windows replace the need for tmux in daily use):
`Ctrl+Shift+Enter` split (auto direction), `Ctrl+Alt+\` vertical split, `Ctrl+Alt+-` horizontal split, `Ctrl+Alt+H/J/K/L` move between panes, `Ctrl+Alt+Z` zoom the current pane (toggle).

**Kittens** (small helper programs bundled with kitty, run as `kitten <name>`):

```bash
kitten icat photo.png                 # show an image right in the terminal
kitten diff old.c new.c               # side-by-side, syntax-highlighted diff
kitten ssh user@host                  # ssh that also brings your kitty config/terminfo along
kitten themes                         # browse and apply color themes interactively
kitten hints --type path --program -  # print a clicked/typed-hint path (scriptable)
echo hello | kitten clipboard         # copy to the clipboard (also works over ssh)
```

**Remote control** (script kitty itself): add `allow_remote_control yes` to `kitty.conf`, restart kitty, then for example `kitty @ ls` (JSON of windows/tabs), `kitty @ launch --type=tab --cwd=/some/dir`, `kitty @ send-text --match title:build 'make\n'`.

**Sessions:** a text file with `launch` lines opens a prepared layout: `kitty --session ~/dev.session`.

## zsh and oh-my-zsh

**What:** zsh is the shell. oh-my-zsh is a plugin framework (cloned to `~/.oh-my-zsh`) that gives themes and plugins. Your zshrc is used as it was: theme `filip`, plugins `git` (aliases like `gst`, `gco`, `gp`) and `zsh-syntax-highlighting` (valid commands turn green, typos red; it lives in `~/.config/zsh/custom/plugins/` because your zshrc points `ZSH_CUSTOM` there). Added at the end of the file: `~/.local/bin` on PATH, `EDITOR` falling back to `nvim`, fzf key bindings, and `lfcd` on `Ctrl+O`.

Customize in `dotfiles/zsh/zshrc`: change `ZSH_THEME` (list: `ls ~/.oh-my-zsh/themes`), add plugin names to `plugins=(...)` (list: `ls ~/.oh-my-zsh/plugins`). Update everything with `./install.sh --update` or just `git -C ~/.oh-my-zsh pull`.

Useful built-ins: `Ctrl+R` history search (fzf), `Ctrl+A` / `Ctrl+E` line start/end, `Alt+.` last argument of the previous command, `!!` the previous command (`sudo !!`), `cd -` previous directory, `**/*.cpp` recursive glob.

---

## Wayland and desktop utilities

**Clipboard (`wl-clipboard`, `cliphist`)**

```bash
echo hello | wl-copy              # stdin -> clipboard
wl-paste > out.txt                # clipboard -> stdout
wl-copy < image.png               # works with images too
cliphist list | rofi -dmenu | cliphist decode | wl-copy   # clipboard history picker (Alt+Shift+V)
```

**Screenshots (`grim`, `slurp`, `swappy`)**

```bash
grim shot.png                           # whole screen
grim -g "$(slurp)" shot.png             # select a region with the mouse
grim -g "$(slurp)" - | wl-copy          # region straight to the clipboard
grim -g "$(slurp)" - | swappy -f -      # region into the annotation editor (the Print key)
```

**Sway control (`swaymsg`)**

```bash
swaymsg -t get_tree        # every window as JSON: app_id, name, workspace, size
swaymsg -t get_outputs     # outputs and their names (for switch-display and `output` lines)
swaymsg -t get_workspaces
swaymsg workspace number 3
swaymsg exec kitty
swaymsg reload             # re-read the config (Alt+Shift+C)
sway -C                    # validate the config without applying it
swaymsg -t get_workspaces -r | jq -r '.[].name'   # JSON output is what the eww scripts consume
```

**Audio (`wpctl`, `pavucontrol`, `playerctl`)**

```bash
wpctl status                                     # sinks, sources, ids
wpctl get-volume @DEFAULT_AUDIO_SINK@
wpctl set-volume @DEFAULT_AUDIO_SINK@ 40%
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
wpctl set-default <id>                           # choose the default output (id from `wpctl status`)
playerctl play-pause                             # media keys talk to any MPRIS player (browser, Spotify)
playerctl metadata title
pavucontrol                                      # the GUI mixer
```

**Network (`nmtui`, `nmcli`)**

```bash
nmtui                                            # menu UI: "Activate a connection" to join Wi-Fi
nmcli device wifi list
nmcli device wifi connect "SSID" password "pass"
nmcli connection show
```

**Bluetooth (`bluetoothctl`, `blueman-manager`)**

```bash
bluetoothctl
  power on
  scan on                  # note the device MAC address
  pair AA:BB:CC:DD:EE:FF
  trust AA:BB:CC:DD:EE:FF  # reconnect automatically
  connect AA:BB:CC:DD:EE:FF
```

**Brightness (`brightnessctl`)**: `brightnessctl info`, `brightnessctl set 50%`, `brightnessctl set 5%+`. It controls laptop backlights; most desktop monitors need `ddcutil` instead.

**Wallpaper:** `wallpaper ~/Pictures/photo.jpg` (sets it now and remembers it for next login), `wallpaper restore`.

**Lock and idle:** `loginctl lock-session` locks (also `Alt+Escape`). Timeouts are the variables `$lock_timeout` and `$screen_off_timeout` at the top of `~/.config/sway/config` (seconds). swayidle reads them at startup: log out and in, or `pkill swayidle` and re-run the `swayidle` line from `autostart.conf`.

**Monitors:** `switch-display '^HDMI'` keeps only matching outputs enabled, `switch-display all` enables everything (names from `swaymsg -t get_outputs`; it refuses to disable every output).

**X11 apps:** they run automatically through Xwayland. `xprop` and `xdpyinfo` work for X11 windows only. A window is X11 if `swaymsg -t get_tree` shows `"shell": "xwayland"` for it.

---

## Fedora basics (dnf, systemd)

```bash
sudo dnf install pkg              sudo dnf remove pkg          sudo dnf autoremove
dnf search keyword                dnf info pkg                 dnf list --installed | rg name
sudo dnf upgrade                  # update everything from every enabled repo
dnf provides '*/bin/convert'      # which package ships this file/command?
dnf history                       # transactions; `sudo dnf history undo <id>` reverts one
dnf repolist                      # enabled repos (RPM Fusion, VS Code, Brave)
rpm -qf /usr/bin/kitty            # which package owns a file

systemctl status greetd           journalctl -b -u greetd      # service state and its logs for this boot
sudo systemctl enable --now bluetooth
systemctl --user status pipewire  # user services (audio)
```
