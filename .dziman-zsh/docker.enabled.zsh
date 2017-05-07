alias docker-refresh='eval "$(docker-machine env adfury)"'

#local adfury-machine-status=$(docker-machine status adfury)
if [[ $(docker-machine status adfury) = "Running" ]]; then
    eval "$(docker-machine env adfury)"
fi
