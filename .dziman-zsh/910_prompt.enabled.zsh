#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Prompt settings # TODO Improve
################################################################################
autoload -U colors
colors

autoload -Uz add-zsh-hook


PREVIOUS_SEGMENT_COLOR='NONE'

LEFT_PROMPT_START_SEPARATOR='\uE0B6'
LEFT_PROMPT_SEPARATOR="$icons[LEFT_SEGMENT_SEPARATOR]"

RIGHT_PROMPT_END_SEPARATOR='\uE0B4'
RIGHT_PROMPT_SEPARATOR="$icons[RIGHT_SEGMENT_SEPARATOR]"

function print-segment() {
  local segment_fg=$1
  local segment_bg=$2
  local content=$3

  if [[ $content != "" ]]; then
    if [[ "$PREVIOUS_SEGMENT_COLOR" == "NONE" ]]; then
      echo -n "%k%F{$segment_bg}$LEFT_PROMPT_START_SEPARATOR%K{$segment_bg}%F{$segment_fg}"
    else
      echo -n " %F{$PREVIOUS_SEGMENT_COLOR}%K{$segment_bg}$LEFT_PROMPT_SEPARATOR%F{$segment_fg}"
    fi

    echo -n " $content"

    PREVIOUS_SEGMENT_COLOR=$segment_bg
  fi
}

function print-left-prompt-end() {
  echo -n " %F{$PREVIOUS_SEGMENT_COLOR}%k$LEFT_PROMPT_SEPARATOR%f"
  PREVIOUS_SEGMENT_COLOR='NONE'
}

function print-right-segment() {
  local segment_fg=$1
  local segment_bg=$2
  local content=$3

  if [[ $content != "" ]]; then
    if [[ "$PREVIOUS_SEGMENT_COLOR" == "NONE" ]]; then
      echo -n "%k%F{$segment_bg}$RIGHT_PROMPT_SEPARATOR%K{$segment_bg}%F{$segment_fg}"
    else
      echo -n " %F{$segment_bg}$RIGHT_PROMPT_SEPARATOR%F{$segment_fg}%K{$segment_bg}"
    fi

    echo -n " $content"

    PREVIOUS_SEGMENT_COLOR=$segment_bg
  fi
}

function print-right-prompt-end() {
  if [[ "$PREVIOUS_SEGMENT_COLOR" != "NONE" ]]; then
    echo -n " %F{$PREVIOUS_SEGMENT_COLOR}%k$RIGHT_PROMPT_END_SEPARATOR%f"
    PREVIOUS_SEGMENT_COLOR='NONE'
  fi
}

# TODO Implement
function user-host() {
  # if ssh then show server icon and host name, show current username
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    echo -n "$icons[SERVER_ICON]"
  else # if local then show laptop icon, show username only if su was used
    echo -n "$icons[LAPTOP_ICON]"
  fi
}

# TODO Use variables for colors
function left-prompt() {
  print-segment 10 246 "$(user-host)"
  print-segment 10 66 "$(current-dir)"
  print-left-prompt-end
}

# TODO Use variables for colors
function right-prompt() {
  print-right-segment 10 111 "$(jenv-status)"
  print-right-segment 10 103 "$(git-prompt-status)"
  print-right-prompt-end
}

function update-right-prompt() {
  RPS1="$(right-prompt)%{$reset_color%}"
}

# TODO Parse and butify
function current-dir() {
  echo "%~"
}

################################################################################
# Git status information
################################################################################
# TODO Move to git extension?
# TODO Use icons and prompt background color
function git-prompt-status() {
  local -a git_status
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

  if [[ $? == 0 ]]; then

    git_status+=$branch

    local ahead behind stashes changenum
    local -a remotestatus

    ahead=$(git rev-list @{upstream}..HEAD &>/dev/null)
    if [[ $? == 0 ]]; then
      ahead=$(git rev-list @{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
      behind=$(git rev-list HEAD..@{upstream} 2>/dev/null | wc -l | tr -d ' ')

      if [[ "$ahead" -ge 1 ]]; then
        remotestatus+="%{$fg_bold[green]%}↑$ahead"
      fi
      if [[ "$behind" -ge 1 ]]; then
        remotestatus+="%{$fg_bold[red]%}↓$behind"
      fi

      if [ -z "$remotestatus" ]; then
        remotestatus="%{$fg_bold[cyan]%}≡"
      fi

      git_status+=$remotestatus
    fi

    temp_file_for_git_status=$(mktemp)
    git status --porcelain 2>/dev/null 1>$temp_file_for_git_status
    changesnum=$(count_lines_in_git_status "$temp_file_for_git_status" ".")
    if [[ $changesnum -ge 1 ]]; then
      staged_added=$(count_lines_in_git_status "$temp_file_for_git_status" "^A")
      staged_modified=$(count_lines_in_git_status "$temp_file_for_git_status" "^[MR]")
      staged_deleted=$(count_lines_in_git_status "$temp_file_for_git_status" "^D")
      unstaged_modified=$(count_lines_in_git_status "$temp_file_for_git_status" "^.M")
      unstaged_deleted=$(count_lines_in_git_status "$temp_file_for_git_status" "^.D")
      untracked=$(count_lines_in_git_status "$temp_file_for_git_status" "^\?")
      conflicts=$(count_lines_in_git_status "$temp_file_for_git_status" "^UU")
      if [[ "$conflicts" != "0" ]]; then
        conflicts=" !$conflicts"
      else
        conflicts=""
      fi
      git_status+="%{$fg_bold[green]%}+$staged_added *$staged_modified -$staged_deleted %{$fg_bold[magenta]%}| %{$fg_bold[red]%}+$untracked *$unstaged_modified -$unstaged_deleted$conflicts"
    fi
    rm $temp_file_for_git_status

    stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$stashes" -ge 1 ]]; then
      git_status+="%{$fg_bold[blue]%}$stashes➜ "
    fi

    echo "%{$fg_bold[magenta]%}[%{$fg_bold[cyan]%}$git_status%{$fg_bold[magenta]%}]%f"

  fi
}

function count_lines_in_git_status() {
  echo -n $(cat $1 | $GREP_TOOL "$2" | wc -l | tr -d ' ')
}
################################################################################

################################################################################
# Info about java version for current location
################################################################################
# TODO Move to java extension?
# TODO Handle shell settings
function jenv-status() {
  if which jenv &>/dev/null; then
    local_java=$(jenv version-name 2>/dev/null)
    global_java=$(jenv global 2>/dev/null)
    [[ "$local_java" == "$global_java" ]] || echo -n "%{$fg[white]%}$icons[JAVA_ICON] $local_java%f"
  fi
}
################################################################################

################################################################################
# Show last command execution time # TODO Review
################################################################################
function perf-preexec() {
  timer=$(($(gdate +%s%N)/1000000))
}

function perf-precmd() {
  RPS1=""

  if [ $timer ]; then
    now=$(($(gdate +%s%N)/1000000))
    elapsed=$(($now-$timer))

    export RPS1="$RPS1%{$fg[cyan]%}%F{104}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
}

#add-zsh-hook precmd perf-precmd
#add-zsh-hook preexec perf-preexec
################################################################################

if [[ -o interactive ]]; then

  add-zsh-hook precmd update-right-prompt

  PS1="$icons[MULTILINE_FIRST_PROMPT_PREFIX]$(left-prompt)
$icons[MULTILINE_LAST_PROMPT_PREFIX]%{$reset_color%}"
  PS2="%{$fg[red]%}%_%{$reset_color%}"
  PROMPT3="%{$fg[red]%}Make your choice:%{$reset_color%}"
fi
