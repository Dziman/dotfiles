#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# System settings
################################################################################
#ulimit -n 10000
################################################################################

################################################################################
# Set options
################################################################################

# add custom completion scripts
fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(~/.zsh/completion $fpath)

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
precmd() {
    vcs_info
}

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
#RPS1=$'$(vcs_info_wrapper)'

autoload colors
colors
setopt prompt_subst
PS1=$'${fg_bold[white]}.(%{${fg[green]}%n%}%{${fg_bold[white]}@%}%{${fg[grey]}%m%}${fg_bold[white]})-in-(${fg[cyan]}%~${fg[white]})-$(vcs_info_wrapper)${fg[yellow]}\
-->%{${fg[default]}%}'
#RPS1="%{${bg[default]}%}%{${fg[grey]}%}<%*>%{$fg[default]%}"
PS2="${fg[red]}%_${fg[default]}"
PROMPT3="${fg[red]}Make your choice: ${fg[default]}"
################################################################################

################################################################################
# Directory aliases
################################################################################
export EDITOR=mate

export JAVA_HOME=$(/usr/libexec/java_home)

#disable annoying java icons in doc
export OSX_JAVAOPTS='-Dapple.awt.UIElement=true -Djava.awt.headless=true'

export HOMEBREW_GITHUB_API_TOKEN='e80a9e8846522129ddedae42eedd2f81af214cc1'

export ANDROID_HOME='/Users/dziman/Development/tools/android'
export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH
################################################################################

################################################################################
# Directory aliases
################################################################################

hash -d src=~/Development/src/

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
alias hadoop='/Users/dziman/Development/tools/hadoop/bin/hadoop'
alias start_hadoop='/Users/dziman/Development/tools/hadoop/bin/start-all.sh'
alias stop_hadoop='/Users/dziman/Development/tools/hadoop/bin/stop-all.sh'

alias hbase='/Users/dziman/Development/tools/hbase/bin/hbase'
alias start_hbase='/Users/dziman/Development/tools/hbase/bin/start-hbase.sh'
alias stop_hbase='/Users/dziman/Development/tools/hbase/bin/stop-hbase.sh'

alias start_zoo='/Users/dziman/Development/tools/zookeeper/bin/zkServer.sh start'
alias stop_zoo='/Users/dziman/Development/tools/zookeeper/bin/zkServer.sh stop'

alias play='/Users/dziman/Development/tools/play/play'

alias blc='mvn clean install -P dev -projects lc-ui --also-make'

alias tools_start='/Users/dziman/Development/tools/tools-tomcat/bin/catalina.sh start'
alias tools_stop='/Users/dziman/Development/tools/tools-tomcat/bin/catalina.sh stop'

alias tomcat_start='/Users/dziman/Development/tools/apache-tomcat-6.0.26/bin/catalina.sh start'
alias tomcat_stop='/Users/dziman/Development/tools/apache-tomcat-6.0.26/bin/catalina.sh stop'

alias start_amq='/Users/dziman/Development/tools/activemq/bin/macosx/activemq start'
alias stop_amq='/Users/dziman/Development/tools/activemq/bin/macosx/activemq stop'

alias redis_start='redis-server /usr/local/etc/redis.conf'

alias use_jdk_6='export JAVA_HOME=/Library/Java/JavaVirtualMachines/1.6.0_26-b03-383.jdk/Contents/Home'
alias use_jdk_7='export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_51.jdk/Contents/Home'
alias use_jdk_8='export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_11.jdk/Contents/Home'
alias use_default_jdk='export JAVA_HOME=$(/usr/libexec/java_home)'
################################################################################

################################################################################
# GIT aliases
################################################################################
alias gmm='git merge origin/master'
alias gmd='git merge origin/develop'
alias gpom='git push origin master'
alias gpod='git push origin develop'
alias gca='git commit -a'
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

# Completion for git-flow-avh from Homebrew
source /usr/local/share/zsh/site-functions/git-flow-completion.zsh

################################################################################

################################################################################
# Ruby specific
################################################################################

# export PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
# source ~/.rvm/scripts/rvm
# rvm use 1.9.3 > /dev/null

################################################################################

################################################################################
# Go specific
################################################################################

export GOROOT=/usr/local/go
export GOPATH=/Users/dziman/Development/src/go
export PATH=$PATH:$GOPATH/bin

################################################################################
