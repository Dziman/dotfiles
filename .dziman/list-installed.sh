#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# List all installed packages, extensions
################################################################################

brew list > ~/.dziman/brew.packages
brew cask list > ~/.dziman/brew.cask.packages
code --version > /dev/null 2>&1
if [[ $? == 0 ]]; then
    code --list-extensions > ~/.dziman/vs.code.extensions
fi
################################################################################
