#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# JavaScript specific
################################################################################

export NVM_DIR="$HOME/.nvm"

[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Completions from zsh-completions package provide better info so this is disabled for now
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
