#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# JetBrains IDEA specific
################################################################################

function open-idea() {
  local app
  for app in "IntelliJ IDEA 2026.x EAP" "IntelliJ IDEA"; do
    if [[ -d "/Applications/$app.app" ]]; then
      open -na "$app" --args "$@"
      return
    fi
  done
  echo "No installed IDEA found" >&2
  return 13
}

alias idea=open-idea
alias ideal='idea --line'
