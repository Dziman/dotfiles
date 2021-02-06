#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# JetBrains IDEA specific
################################################################################

function open-idea() {
    open -na "IntelliJ IDEA 2021.x EAP" --args "$@"
}

alias idea=open-idea
