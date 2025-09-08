#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Emacs specific functions and aliases
################################################################################

alias emacs='emacs --no-window-system'
alias edit='emacsclient --tty'
alias edit-wiki='edit --socket-name personal-wiki-emacs'
alias edit-config='edit --socket-name configs-emacs'
alias emacs-wip='DZIMAN_EMACS_SETTINGS_DIR="~/src/idr/settings/.emacs-dziman" emacs --no-window-system --no-init-file --load ~/src/idr/settings/.emacs'
alias emacs-ui-wip='DZIMAN_EMACS_SETTINGS_DIR="~/src/idr/settings/.emacs-dziman" /Applications/Emacs.app/Contents/MacOS/Emacs --no-init-file --load ~/src/idr/settings/.emacs'
alias emacs-31-wip='DZIMAN_EMACS_SETTINGS_DIR="~/src/idr/settings/.emacs-dziman" /Applications/Emacs.app/Contents/MacOS/emacs-nw --no-init-file --load ~/src/idr/settings/.emacs'
