#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# JetBrains IDEA specific
################################################################################

function open-idea() {
  open -na "IntelliJ IDEA" --args "$@"
}

alias idea=open-idea
alias ideal='idea --line'
