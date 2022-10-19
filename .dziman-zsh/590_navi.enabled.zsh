#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# navi (https://github.com/denisidoro/navi)
################################################################################

# custom cheatsheets location
export NAVI_CONFIG="$HOME/.navi/config.yaml"

function init-navi-shell-widget() {
  eval "$(navi widget zsh)"

  zle -N _navi_call
  zle -N _navi_widget

  bindkey '^n' _navi_widget
  bindkey '^g' send-break
}

if [[ -o interactive ]] && which navi &>/dev/null; then
  init-navi-shell-widget
fi
