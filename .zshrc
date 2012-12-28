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

HISTFILE=~/.histfile
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

# Complition
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -a zsh/zprof zprof
zmodload -ap zsh/mapfile mapfile

################################################################################

################################################################################
# Promts
################################################################################
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git cvs svn


# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stangedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}
RPS1=$'$(vcs_info_wrapper)'

autoload colors
colors
PS1="${fg_bold[white]}.(%{${fg[green]}%n%}%{${fg_bold[white]}@%}%{${fg[grey]}%m%}${fg_bold[white]})-in-(\
${fg[cyan]}%~\
${fg[white]})-
${fg[yellow]}-->%{${fg[default]}%}"
#RPS1="%{${bg[default]}%}%{${fg[grey]}%}<%*>%{$fg[default]%}"
PS2="${fg[red]}%_${fg[default]}"
PROMPT3="${fg[red]}Make your choice: ${fg[default]}"
################################################################################

export PATH=/opt/local/bin:/opt/local/sbin:$PATH
export EDITOR=mate

################################################################################
# Directory aliases
################################################################################

hash -d jsrc=~/Development/src/java/

################################################################################

################################################################################
# General aliases
################################################################################
alias cls='clear'
alias ls='ls -F -G'
alias ee='emacs'
alias mv='mv -i'
alias mate='/Applications/TextMate.app/Contents/Resources/mate'
################################################################################

################################################################################
# Java aliases
################################################################################
alias hadoop='/Users/dziman/Development/libs/bin/hadoop/bin/hadoop'
alias start_hadoop='/Users/dziman/Development/libs/bin/hadoop/bin/start-all.sh'
alias stop_hadoop='/Users/dziman/Development/libs/bin/hadoop/bin/stop-all.sh'

alias hbase='/Users/dziman/Development/libs/bin/hbase/bin/hbase'
alias start_hbase='/Users/dziman/Development/libs/bin/hbase/bin/start-hbase.sh'
alias stop_hbase='/Users/dziman/Development/libs/bin/hbase/bin/stop-hbase.sh'

alias start_zoo='/Users/dziman/Development/libs/bin/zookeeper/bin/zkServer.sh start'
alias stop_zoo='/Users/dziman/Development/libs/bin/zookeeper/bin/zkServer.sh stop'

alias play='/Users/dziman/Development/libs/bin/play/play'

alias blc='mvn clean install -P dev -projects lc-ui --also-make'

alias tools_start='/Users/dziman/Development/libs/bin/tools-tomcat/bin/catalina.sh start'
alias tools_stop='/Users/dziman/Development/libs/bin/tools-tomcat/bin/catalina.sh stop'
################################################################################

################################################################################
# Keybindings
################################################################################
bindkey -e

autoload -U incremental-complete-word
zle -N incremental-complete-word
bindkey "^Xi" incremental-complete-word ## C-x-i

bindkey '\e[3~' delete-char
################################################################################

################################################################################
# Completions
################################################################################
export LSCOLORS=GxFxCxDxBxegedabagaced

zstyle ':completion:*:default' list-colors 'no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;31:'

zstyle ':completion:*' completer _complete _list _oldlist _expand _ignored _match _correct _approximate _prefix
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' add-space true

zstyle ':completion:*:processes' command 'ps -xf'
zstyle ':completion:*:processes-names' command 'ps xho command'

zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always

zstyle ':completion:*:cd:*' ignore-parents parent pwd

zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:functions' ignored-patterns '_*'

zstyle ':completion:*' menu select=long-list select=0
zstyle ':completion:*' old-menu false
zstyle ':completion:*' original true
zstyle ':completion:*' substitute 1
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' word true

source .zsh_git_flow

################################################################################