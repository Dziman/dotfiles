#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Aliases
################################################################################

# General
alias cls='clear'

if command-exists gls; then
    alias ls='gls --classify --human-readable --color=auto'
else
    alias ls='ls -C -p --color=auto'
fi

if command-exists gmv; then
    alias mv='gmv --interactive'
else    
    alias mv='mv -i'
fi

# command to track dotfiles by git
alias config='git --git-dir=$HOME/.dziman-dotfiles/ --work-tree=$HOME'
