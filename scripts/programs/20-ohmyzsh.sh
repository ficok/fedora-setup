#!/usr/bin/env bash
# oh-my-zsh and the plugins from your zshrc, installed from git. Re-run = update.
# Your zshrc sets ZSH_CUSTOM=$HOME/.config/zsh/custom, so plugins go there.
set -euo pipefail
. "$(dirname "$0")/../../lib/common.sh"

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
CUSTOM="${ZSH_CUSTOM:-$HOME/.config/zsh/custom}"

git_sync https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
mkdir -p "$CUSTOM/plugins"
git_sync https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
ok "oh-my-zsh and zsh-syntax-highlighting up to date (the .zshrc comes from dotfiles/zsh)."
