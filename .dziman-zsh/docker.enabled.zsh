alias docker-refresh='eval "$(docker-machine env main-docker)"'

if [[ $(docker-machine status main-docker 2>/dev/null) = "Running" ]]; then
    eval "$(docker-machine env main-docker)"
fi
