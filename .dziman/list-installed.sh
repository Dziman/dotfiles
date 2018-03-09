#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# List all installed packages, extensions
################################################################################

brew list > brew.packages
brew cask list > brew.cask.packages
code --list-extensions > vs.code.extensions
################################################################################
