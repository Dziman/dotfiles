#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Prompt segment: hydra feature branch => base branch
################################################################################

function profile-prompt-status() {
  if hydra info &>/dev/null; then
    echo -n "$(hydra info --feature) => $(hydra info --base)"
  fi
}
