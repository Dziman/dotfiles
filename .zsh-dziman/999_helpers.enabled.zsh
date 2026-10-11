#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Misc helper functions
################################################################################

################################################################################
# Print terminal color numbers using that color
################################################################################
function print-color-palette() {
  for i in {0..255}; do
    printf "\x1b[38;5;${i}m%3d " "${i}"
    if (($i == 15)) || (($i > 15)) && ((($i - 15) % 12 == 0)); then
      echo
    fi
  done
}
################################################################################

################################################################################
# List all installed packages, extensions
################################################################################
# Snapshots of this machine go to its profile (~/.dziman/profiles/<p>/.dziman/).
function list-installed() {
  local out=~/.dziman/profile/.dziman
  [[ -d ~/.dziman/profile ]] || { echo "list-installed: no profile set (config profile <name>)" >&2; return 1; }
  mkdir -p $out
  brew list --formulae >$out/brew.packages
  brew list --cask >$out/brew.cask.packages
  brew tap >$out/brew.taps
  code --version >/dev/null 2>&1
  if [[ $? == 0 ]]; then
    code --list-extensions >$out/vs.code.extensions
  fi
}
################################################################################
