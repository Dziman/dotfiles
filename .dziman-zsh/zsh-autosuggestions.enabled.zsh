#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Autosuggest commands
################################################################################

if [[ -a ~/.dziman-zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
   source ~/.dziman-zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
   # TODO Add git clone?
   # git://github.com/zsh-users/zsh-autosuggestions
   echo "zsh autosuggestions not found. Clone from git://github.com/zsh-users/zsh-autosuggestions to ~/.dziman-zsh/zsh-autosuggestions/"
fi

