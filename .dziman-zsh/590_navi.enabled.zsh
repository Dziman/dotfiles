#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# navi (https://github.com/denisidoro/navi)
################################################################################

# custom cheatsheets location
export NAVI_PATH="$HOME/.local/share/navi"

function init-navi-shell-widget() {
    eval "$(navi widget zsh)"

    zle -N _navi_call

    bindkey '^n' _navi_call
    bindkey '^g' send-break
}

if [[ -o interactive ]] && which navi &>/dev/null; then
    init-navi-shell-widget
fi
