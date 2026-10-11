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

autoload -U compinit # Run once in 005_completions, after `fpath` is final

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

# Machine profile, selected with `config profile <name>` (~/.dziman/profile -> profiles/<name>)
export DZIMAN_PROFILE="${$(readlink ~/.dziman/profile 2>/dev/null):t}"

# Include all enabled extensions
for extension_file in ~/.zsh-dziman/*.enabled.zsh; do
    source "$extension_file"
done

# Profile-specific extensions, sourced last so they can override shared ones
for extension_file in ~/.dziman/profile/.zsh-dziman/*.zsh(N); do
    source "$extension_file"
done
################################################################################
