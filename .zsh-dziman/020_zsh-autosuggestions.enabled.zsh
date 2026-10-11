#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Autosuggest commands
################################################################################

if [[ -o interactive ]]; then
  if [[ -e $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  else
    echo "zsh autosuggestions not found. Please install using `brew install zsh-autosuggestions`"
  fi
fi
