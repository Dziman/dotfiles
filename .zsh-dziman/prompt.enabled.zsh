#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Prompt settings
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

# TODO Move to git extension?
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

# TODO Move to java extension?
jenv_status() {
    if which jenv &>/dev/null; then
	local_java=$(jenv version-name 2>/dev/null)
	global_java=$(jenv global 2>/dev/null)
	[[ "$local_java" == "$global_java" ]] || echo -n "%{$fg_bold[red]%}[Local java $local_java]%{$reset_color%} "
    fi    
}

PS1=$'$(user_host)%{$fg_bold[white]%}-in-$(current_dir)%{$fg_bold[white]%}-%{$reset_color%}
$(jenv_status)$(prompt_vcs_info)$(custom_git)%{$fg[yellow]%}➤%{$reset_color%} '
RPS1="%{$fg[grey]%}<%*>%{$reset_color%}"
PS2="%{$fg[red]%}%_%{$reset_color%}"
PROMPT3="%{$fg[red]%}Make your choice:%{reset_color%}"
