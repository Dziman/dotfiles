#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# General development tools
################################################################################

# anyenv initialization
if [[ -o interactive ]] && command-exists anyenv; then eval "$(anyenv init - zsh)"; fi

# node env
export NVM_DIR="$HOME/.nvm"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"  # This loads nvm
[[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion" ]] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion  
