#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Python specific
################################################################################

# jenv initialization
if [[ -o interactive ]] && which pyenv > /dev/null; then eval "$(pyenv init -)"; fi