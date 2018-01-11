#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Prompt settings
################################################################################
autoload colors
colors

function user_host() {
    echo "%{$fg_bold[white]%}.(%{$fg[green]%}%n%{$fg_bold[white]%}@%{$fg[grey]%}%m%{$fg_bold[white]%})"
}

function current_dir() {
    echo "%{$fg[white]%}(%{$fg[cyan]%}%~%{$fg[white]%})"
}

################################################################################
# Git status information
################################################################################
# TODO Move to git extension?
function custom_git() {
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

	temp_file_for_git_status=$(mktemp)
	git status --porcelain 2>/dev/null 1>$temp_file_for_git_status
	changesnum=$(count_lines_in_git_status "$temp_file_for_git_status" ".")
	if [[ $changesnum -ge 1 ]]; then
	    staged_added=$(count_lines_in_git_status "$temp_file_for_git_status" "^A")
	    staged_modified=$(count_lines_in_git_status "$temp_file_for_git_status" "^[MR]")
	    staged_deleted=$(count_lines_in_git_status "$temp_file_for_git_status" "^D")
	    unstaged_modified=$(count_lines_in_git_status "$temp_file_for_git_status" "^.M")
	    unstaged_deleted=$(count_lines_in_git_status "$temp_file_for_git_status" "^.D")
	    untracked=$(count_lines_in_git_status "$temp_file_for_git_status" "^\?")
	    conflicts=$(count_lines_in_git_status "$temp_file_for_git_status" "^UU")
	    if [[ "$conflicts" != "0" ]]; then
		conflicts=" !$conflicts"
	    else
		conflicts=""
	    fi	    
            git_status+="%{$fg_bold[green]%}+$staged_added *$staged_modified -$staged_deleted %{$fg_bold[magenta]%}| %{$fg_bold[red]%}+$untracked *$unstaged_modified -$unstaged_deleted$conflicts"
	fi
	rm $temp_file_for_git_status
	
	stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
	if [[ "$stashes" -ge 1 ]]; then
	    git_status+="%{$fg_bold[blue]%}$stashes➜ "
	fi

	echo "%{$fg_bold[magenta]%}[%{$fg_bold[cyan]%}$git_status%{$fg_bold[magenta]%}]%{$reset_color%}"

    fi
}

function count_lines_in_git_status() {
    echo -n $(cat $1 | grep "$2" | wc -l | tr -d ' ')
}
################################################################################

################################################################################
# Info about java version for current location
################################################################################
# TODO Move to java extension?
function jenv_status() {
    if which jenv &>/dev/null; then
	local_java=$(jenv version-name 2>/dev/null)
	global_java=$(jenv global 2>/dev/null)
	[[ "$local_java" == "$global_java" ]] || echo -n "%{$fg_bold[red]%}[Local java $local_java]%{$reset_color%} "
    fi    
}
################################################################################

################################################################################
# Show last command execution time
################################################################################
function preexec() {
    timer=$(($(gdate +%s%N)/1000000))
}

function precmd() {
    RPS1=""

    if [ $timer ]; then
        now=$(($(gdate +%s%N)/1000000))
        elapsed=$(($now-$timer))

        export RPS1="$RPS1%{$fg[cyan]%}%F{104}${elapsed}ms %{$reset_color%}"
        unset timer
    fi
}
################################################################################

################################################################################
# Highlight syntax in prompt
################################################################################
if [ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
################################################################################

PS1=$'$(user_host)%{$fg_bold[white]%}-in-$(current_dir)%{$fg_bold[white]%}-%{$reset_color%}
$(jenv_status)$(custom_git)%{$fg[yellow]%}➤%{$reset_color%} '
PS2="%{$fg[red]%}%_%{$reset_color%}"
PROMPT3="%{$fg[red]%}Make your choice:%{reset_color%}"
