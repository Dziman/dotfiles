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
export PATH="$HOME/src/apple/aos-ado/dpe-extension/bin:$PATH"
export PATH="$HOME/src/apple/aos-me/merch-scripts/bin:$PATH"
export HOMEBREW_PREFIX=$(brew --prefix)

export LSCOLORS=GxFxCxDxBxegedabagaced

GREP_TOOL="grep"

if command-exists rg; then
  GREP_TOOL="rg"

  # ripgrep config file definition
  export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi

export GREP_TOOL

## TODO Move to more specific file?
export GUM_CHOOSE_SHOW_HELP="false"
export GUM_CONFIRM_SHOW_HELP="false"
