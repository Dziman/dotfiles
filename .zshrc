#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# Set options
################################################################################
setopt localoptions
setopt localtraps
setopt promptsubst
setopt histignorealldups
setopt autocd
setopt appendhistory
setopt beep
setopt nomatch
setopt notify
setopt correct
unsetopt extendedglob
setopt AUTO_PUSHD

mkdir ~/.zsh/ 2>/dev/null
HISTFILE=~/.zsh/_histfile
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

autoload -U compinit
compinit

autoload -U promptinit
promptinit

autoload -U insert-files
zle -N insert-files

autoload -U predict-on
zle -N predict-on

autoload -U colors
colors

bindkey -e

autoload -U incremental-complete-word
zle -N incremental-complete-word
bindkey "^Xi" incremental-complete-word ## C-x-i

bindkey '\e[3~' delete-char
################################################################################

################################################################################
# Extensions
################################################################################

# Include all enabled extensions
for extension_file in ~/.dziman-zsh/*.enabled.zsh; do
    source "$extension_file"
done
################################################################################


# Vite+ bin (https://viteplus.dev)
. "/Users/dziman/.vite-plus/env"

# >>> otty shell integration >>>
# Added by Otty — toggle in Settings > Shell > Shell Integration.
# Inert unless launched by Otty (it sets $OTTY_SHELL_INTEGRATION).
if [ -n "$OTTY_SHELL_INTEGRATION" ] && [ -r "$OTTY_SHELL_INTEGRATION/otty-integration.zsh" ]; then
  . "$OTTY_SHELL_INTEGRATION/otty-integration.zsh"
fi
# <<< otty shell integration <<<
