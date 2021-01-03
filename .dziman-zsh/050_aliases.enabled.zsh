#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Aliases
################################################################################

# Directory
hash -d src=~/Development/src/

# General
alias cls='clear'
alias ls='gls --classify --human-readable --color=always'
alias mv='mv -i'
alias k='k --human'

# command to track dotfiles by git
alias config='git --git-dir=$HOME/.dziman-dotfiles/ --work-tree=$HOME'

# x86 arch brew alias
alias xbrew='arch -x86_64 /usr/local/Homebrew/bin/brew'
