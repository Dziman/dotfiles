#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Python specific
################################################################################

# pyenv initialization
if [[ -o interactive ]] && command-exists pyenv; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# TODO Add auto switch to virtual env if found
