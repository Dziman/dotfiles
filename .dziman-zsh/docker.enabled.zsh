#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Docker shell enhancments
################################################################################
alias docker-refresh='eval "$(docker-machine env main-docker)"'
alias docker-clean-images='docker images --quiet --filter=dangling=true | xargs docker rmi --force'

if [[ $(docker-machine status main-docker 2>/dev/null) = "Running" ]]; then
    eval "$(docker-machine env main-docker)"
fi
