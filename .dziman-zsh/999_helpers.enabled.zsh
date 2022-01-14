#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Misc helper functions
################################################################################

################################################################################
# Print terminal color numbers using that color
################################################################################
function print-color-palette() {
  for i in {0..255} ; do
    printf "\x1b[38;5;${i}m%3d " "${i}"
      if (( $i == 15 )) || (( $i > 15 )) && (( ($i-15) % 12 == 0 )); then
        echo;
      fi
  done
}
################################################################################

################################################################################
# List all installed packages, extensions
################################################################################
function list-installed() {
  brew list --formulae > ~/.dziman/brew.packages
  brew list --cask > ~/.dziman/brew.cask.packages
  code --version > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    code --list-extensions > ~/.dziman/vs.code.extensions
  fi
}
################################################################################
