#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# List all installed packages, extensions
################################################################################

brew list > ~/.dziman/brew.packages
brew cask list > ~/.dziman/brew.cask.packages
code --list-extensions > ~/.dziman/vs.code.extensions
################################################################################
