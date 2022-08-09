#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

alias mvnp='mvn -T1.5C'

# jenv initialization
if [[ -o interactive ]] && which jenv > /dev/null; then eval "$(jenv init - zsh)"; fi
