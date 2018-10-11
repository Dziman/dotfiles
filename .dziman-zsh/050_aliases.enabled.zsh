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
alias emacs='emacs --no-window-system'
alias edit='emacsclient -t'
alias ec='emacsclient -t'
alias ke='emacsclient --eval "(save-buffers-kill-emacs)"'
alias mv='mv -i'
alias k='k --human'

# git
alias gmm='git merge origin/master'
alias gmd='git merge origin/develop'
alias gpom='git push origin master'
alias gpod='git push origin develop'
alias gca='git commit --all'

# command to track dotfiles by git
alias config='git --git-dir=$HOME/.dziman-dotfiles/ --work-tree=$HOME'

alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
