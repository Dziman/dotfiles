#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Customize ls colors using vivid util
################################################################################

if [[ -o interactive ]] && which vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate solarized-dark)"
fi
