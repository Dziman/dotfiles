#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# General development tools
################################################################################

# anyenv initialization
if [[ -o interactive ]] && command-exists anyenv; then eval "$(anyenv init - zsh)"; fi

# node env
export NVM_DIR="$HOME/.nvm"
[[ -s "/usr/local/opt/nvm/nvm.sh" ]] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[[ -s "/usr/local/opt/nvm/etc/bash_completion" ]] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion  
