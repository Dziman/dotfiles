#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Aliases
################################################################################

# General
alias cls='clear'
alias ls='gls --classify --human-readable --color=always'
alias mv='mv -i'
alias k='k --human'

# command to track dotfiles by git
alias config='git --git-dir=$HOME/.dziman-dotfiles/ --work-tree=$HOME'
