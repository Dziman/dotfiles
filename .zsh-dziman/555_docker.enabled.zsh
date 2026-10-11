#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Docker shell enhancments
################################################################################

if command-exists docker; then
  alias docker-refresh='eval "$(docker-machine env main-docker)"'
  alias docker-clean-images='docker images --quiet --filter=dangling=true | xargs docker rmi --force'
  alias docker-start='docker-machine start main-docker && docker-refresh'

  if [[ $(docker-machine status main-docker 2>/dev/null) = "Running" ]]; then
    eval "$(docker-machine env main-docker)"
  fi

fi
