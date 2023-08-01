#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Environment variables
################################################################################

export ALTERNATE_EDITOR=""
export EDITOR=emacsclient

# Homebrew configuration
export HOMEBREW_NO_AUTO_UPDATE="true"
export HOMEBREW_NO_GITHUB_API="true"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.speedy/bin:$PATH"

export LSCOLORS=GxFxCxDxBxegedabagaced

GREP_TOOL="grep"

if [ -x "$(command -v rg)" ]; then
  GREP_TOOL="rg"
fi

export GREP_TOOL
