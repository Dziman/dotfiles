#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Autosuggest commands
################################################################################

if [[ -o interactive ]]; then
  local brew_prefix=$(brew --prefix)
  local zsh_autos_script="${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

  if [[ -a "${zsh_autos_script}" ]]; then
    source "${zsh_autos_script}"
  else
    echo "zsh-autosuggestions is not installed. Please install `brew install zsh-autosuggestions`"
  fi
fi

