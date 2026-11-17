# oh-my-zsh Bureau Theme

### NVM

ZSH_THEME_NVM_PROMPT_PREFIX="%B⬡%b "
ZSH_THEME_NVM_PROMPT_SUFFIX=""

### Git [±master ▾●]

ZSH_THEME_GIT_PROMPT_PREFIX="%{$bg[yellow]%}%{$fg_bold[blue]%}± %{$reset_color%}%{$bg[yellow]%}%{$fg_bold[black]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$bg[yellow]%}%{$fg_bold[blue]%}✓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$bg[yellow]%}%{$fg[cyan]%}▴ %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$bg[yellow]%}%{$fg[magenta]%}▾ %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$bg[yellow]%}%{$fg_bold[green]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$bg[yellow]%}%{$fg_bold[black]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$bg[yellow]%}%{$fg_bold[red]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_STASHED="%{$bg[yellow]%}(%{$fg_bold[blue]%}✹%{$reset_color%})"

bureau_git_info () {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

bureau_git_status() {
  local result gitstatus
  gitstatus="$(command git status --porcelain -b 2>/dev/null)"

  # check status of files
  local gitfiles="$(tail -n +2 <<< "$gitstatus")"
  if [[ -n "$gitfiles" ]]; then
    if [[ "$gitfiles" =~ $'(^|\n)[AMRD]. ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_STAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n).[MTD] ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)\\?\\? ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)UU ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNMERGED"
    fi
  else
    result+="$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  # check status of local repository
  local gitbranch="$(head -n 1 <<< "$gitstatus")"
  if [[ "$gitbranch" =~ '^## .*ahead' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if [[ "$gitbranch" =~ '^## .*behind' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi
  if [[ "$gitbranch" =~ '^## .*diverged' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_DIVERGED"
  fi

  # check if there are stashed changes
  if command git rev-parse --verify refs/stash &> /dev/null; then
    result+="$ZSH_THEME_GIT_PROMPT_STASHED"
  fi

  echo $result
}

bureau_git_prompt() {
  # ignore non git folders and hidden repos (adapted from lib/git.zsh)
  if ! command git rev-parse --git-dir &> /dev/null \
     || [[ "$(command git config --get oh-my-zsh.hide-info 2>/dev/null)" == 1 ]]; then
    return
  fi

  # check git information
  local gitinfo=$(bureau_git_info)
  if [[ -z "$gitinfo" ]]; then
    return
  fi

  # quote % in git information
  local output="${gitinfo:gs/%/%%}"

  # check git status
  local gitstatus=$(bureau_git_status)
  if [[ -n "$gitstatus" ]]; then
    output+=" $gitstatus"
  fi

  echo "%{$bg[yellow]%} %{$reset_color%}${ZSH_THEME_GIT_PROMPT_PREFIX}${output}${ZSH_THEME_GIT_PROMPT_SUFFIX}%{$bg[yellow]%} %{$reset_color%}"
}



_PATH="%{$bg[white]%}%{$fg_bold[grey]%} %~ %{$reset_color%}"
if [[ $EUID -eq 0 ]]; then
  _USERNAME="%{$fg_bold[blue]%} %n! "

else
  _USERNAME="%{$fg_bold[gray]%} %n "

fi

_HOSTNAME="%{$fg_bold[white]%}%m"
_USERNAME="%{$bg[yellow]%}$_USERNAME%{$reset_color%}"
_LIBERTY="%{$bg[black]%}%{$fg[white]%} $_HOSTNAME: %{$reset_color%}"

get_space () {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=$(( COLUMNS - LENGTH - ${ZLE_RPROMPT_INDENT:-1} ))

  (( SPACES > 0 )) || return
  printf ' %.0s' {1..$SPACES}
}

_1LEFT="$_USERNAME%{$bg[black]%} %{$fg[white]%}@ %{$reset_color%}$_PATH"
_1RIGHT="%{$bg[white]%}%{$fg_bold[black]%} %* %{$reset_color%}"

bureau_precmd () {
  _1SPACES=`get_space $_1LEFT $_1RIGHT`
  print
# print -rP "%{$fg[black]%}--------------------------%{$reset_color%}"
  print -rP "$_1LEFT$_1SPACES$_1RIGHT"
}

setopt prompt_subst
PROMPT='$_LIBERTY '
# RPROMPT='$(nvm_prompt_info) $(bureau_git_prompt)'
RPROMPT='$(bureau_git_prompt)'

autoload -U add-zsh-hook
add-zsh-hook precmd bureau_precmd
