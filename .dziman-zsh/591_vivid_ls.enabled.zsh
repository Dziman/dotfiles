#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Customize ls colors using vivid util
################################################################################

if [[ -o interactive ]] && command-exists vivid; then
  export LS_COLORS="$(vivid generate solarized-dark)"
fi
