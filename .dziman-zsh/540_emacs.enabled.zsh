#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Emacs specific functions and aliases
################################################################################

alias emacs='emacs --no-window-system'
alias edit='emacsclient --tty'
alias edit-ui='DZIMAN_EMACSCLIENT_MODE=ui emacsclient --no-wait --create-frame'
alias edit-wiki='edit-ui --socket-name personal-wiki-emacs'
alias edit-config='edit-ui --socket-name configs-emacs'
alias edit-finhea='edit-ui --socket-name finhea'
