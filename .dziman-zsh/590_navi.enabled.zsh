#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# navi (https://github.com/denisidoro/navi)
################################################################################

export NAVI_CONFIG="$HOME/.navi/config.yaml"

function init-navi-shell-widget() {
  eval "$(navi widget zsh)"

  zle -N _navi_call
  zle -N _navi_widget

  bindkey '^n' _navi_widget
  bindkey '^g' send-break
}

if [[ -o interactive ]] && command-exists navi; then
  init-navi-shell-widget
fi
