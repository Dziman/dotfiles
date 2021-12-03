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
eval "$(/opt/homebrew/bin/brew shellenv)"

export LSCOLORS=GxFxCxDxBxegedabagaced

# ripgrep config file definition
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
