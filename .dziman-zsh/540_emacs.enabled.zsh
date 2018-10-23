#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Emacs specific functions and aliases
################################################################################

alias emacs='emacs --no-window-system'
alias edit='emacsclient -t'
alias ec='emacsclient -t'

function ke() {
    if pgrep 'emacs' &>/dev/null; then
        emacsclient --eval "(save-buffers-kill-emacs)"
    fi
}
