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

if [[ -a '/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code' ]]; then
    alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
fi
