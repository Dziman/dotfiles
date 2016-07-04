#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>

################################################################################
# Set options
################################################################################

# add custom completion scripts
fpath=(/usr/local/share/zsh-completions $fpath)

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

source ~/.zsh/.iterm2_shell_integration.zsh

# Fuzzy search
source ~/.zsh/.fzf.zsh

# Colors for man pages
source ~/.zsh/solarized-man.plugin.zsh 

################################################################################

################################################################################
# Promts
################################################################################
autoload colors
colors

autoload -Uz vcs_info

zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f %c%u'
zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f %c%u'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable svn hg
zstyle ':vcs_info:*' check-for-changes true

prompt_vcs_info() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "$vcs_info_msg_0_"
  fi
}

user_host() {
    echo "%{$fg_bold[white]%}.(%{$fg[green]%}%n%{$fg_bold[white]%}@%{$fg[grey]%}%m%{$fg_bold[white]%})"
}

current_dir() {
    echo "%{$fg[white]%}(%{$fg[cyan]%}%~%{$fg[white]%})"
}

custom_git() {
    local -a git_status
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    if [[ $? == 0 ]]; then

	git_status+=$branch

	local ahead behind stashes changenum
	local -a remotestatus

	ahead=$(git rev-list @{upstream}..HEAD &>/dev/null)
	if [[ $? == 0 ]]; then
	    ahead=$(git rev-list @{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
	    behind=$(git rev-list HEAD..@{upstream} 2>/dev/null | wc -l | tr -d ' ')

	    if [[ "$ahead" -ge 1 ]]; then
		    remotestatus+="%{$fg_bold[green]%}↑$ahead"
	    fi
	    if [[ "$behind" -ge 1 ]]; then
		    remotestatus+="%{$fg_bold[red]%}↓$behind"
	    fi

	    if [ -z "$remotestatus" ]; then
		    remotestatus="%{$fg_bold[cyan]%}≡"
	    fi

	    git_status+=$remotestatus
	fi

	stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
	if [[ "$stashes" -ge 1 ]]; then
	    git_status+="%{$fg_bold[blue]%}●$stashes"
	fi

	changesnum=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
	if [[ $changesnum -ge 1 ]]; then
            git_status+="%{$fg_bold[white]%}✏ $changesnum"
	fi

	echo "%{$fg_bold[magenta]%}[%{$fg_bold[cyan]%}$git_status%{$fg_bold[magenta]%}]%{$reset_color%}"

    fi
}

jenv_status() {
    if which jenv &>/dev/null; then
	local_java=$(jenv local 2>/dev/null)
	[[ -n "$local_java" ]] && echo -n "%{$fg_bold[red]%}[Local java $local_java]%{$reset_color%} "
    fi    
}

PS1=$'$(user_host)%{$fg_bold[white]%}-in-$(current_dir)%{$fg_bold[white]%}-%{$reset_color%}
$(jenv_status)$(prompt_vcs_info)$(custom_git)%{$fg[yellow]%}➤%{$reset_color%} '
RPS1="%{$fg[grey]%}<%*>%{$reset_color%}"
PS2="%{$fg[red]%}%_%{$reset_color%}"
PROMPT3="%{$fg[red]%}Make your choice:%{reset_color%}"
################################################################################

################################################################################
# General Env variables
################################################################################
export EDITOR=emacs

# disable annoying java icons in doc TODO It seems Java ignores this
export OSX_JAVAOPTS='-Dapple.awt.UIElement=true -Djava.awt.headless=true'

export HOMEBREW_GITHUB_API_TOKEN='e80a9e8846522129ddedae42eedd2f81af214cc1'

export ALTERNATE_EDITOR="vim"

# Fix Homebrew in El Capitan
export PATH=/usr/local/bin:$PATH

# Add Dotfiles(https://github.com/jbernard/dotfiles) to PATH
export PATH=$PATH:/Users/dziman/Development/src/oss/dotfiles/bin
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
alias emacs='emacs -nw'
alias ec='emacsclient -t'
alias mv='mv -i'
alias mate='/Applications/TextMate.app/Contents/Resources/mate'
################################################################################

################################################################################
# GIT aliases
################################################################################
alias gmm='git merge origin/master'
alias gmd='git merge origin/develop'
alias gpom='git push origin master'
alias gpod='git push origin develop'
alias gca='git commit -a'
alias gf='git-flow'
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

################################################################################

################################################################################
# Java
################################################################################
if which jenv > /dev/null; then eval "$(jenv init -)"; fi
################################################################################

