#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Aliases
################################################################################

# Directory
hash -d src=~/Development/src/

# General
alias cls='clear'
alias ls='gls -Fh --color=always'
alias emacs='emacs -nw'
alias ec='emacsclient -t'
alias mv='mv -i'

# git
alias gmm='git merge origin/master'
alias gmd='git merge origin/develop'
alias gpom='git push origin master'
alias gpod='git push origin develop'
alias gca='git commit -a'
