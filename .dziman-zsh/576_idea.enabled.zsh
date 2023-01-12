#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# JetBrains IDEA specific
################################################################################

function open-idea() {
    if [ -d "/Applications/IntelliJ IDEA 2021.x EAP.app" ]; then
	open -na "IntelliJ IDEA 2021.x EAP.app" --args "$@"
    else
	if [ -d "/Applications/IntelliJ IDEA.app" ]; then
	    open -na "IntelliJ IDEA.app" --args "$@"
	else
	    echo "No installed IDEA found" && return 13
	fi
    fi
}

alias idea=open-idea
alias ideal='idea --line'
