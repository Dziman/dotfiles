#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Python specific
################################################################################

# pyenv initialization
if [[ -o interactive ]] && which pyenv > /dev/null; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
