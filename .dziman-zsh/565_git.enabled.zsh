#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# GIT specific aliases and functions
################################################################################

alias gmm='git merge origin/master'
alias gmd='git merge origin/develop'
alias gpom='git push origin master'
alias gpod='git push origin develop'
alias gca='git commit --all'

function check-git-completion() {
    if [ -f /opt/brew/share/zsh/site-functions/_git ]; then
	echo "$fg_bold[yellow]git completion detected while better alternative exists$reset_color"
    fi
}

function fix-git-completion() {
    if [ -f /opt/brew/share/zsh/site-functions/_git ]; then
	echo "git completion detected while better alternative exists"
	PS3="Do you want delete it? "
	answers=("Yes" "No")
	select answer in "${answers[@]}"
	do
	    case $answer in
		"Yes")
		    rm /opt/brew/share/zsh/site-functions/_git
		    break
		    ;;
		"No")
		    break
		    ;;
		*) echo "Invalid selection";;
	    esac
	done	    
    fi
}

function add-tags-fetching() {
    local remote_name=${1:-origin}

    git config "remote.${remote_name}.tagopt" --tags
}

function stop-tags-fetching() {
    local remote_name=${1:-origin}

    git config "remote.${remote_name}.tagopt" --no-tags
}

function check-tags-config() {
    if [[ -f ".git/config" ]]; then # it seems we are in git repo folder
	local -a remotes=($(git remote))
	if [[ $! == 0 ]]; then
	    for remote in $remotes; do
		tags_config=$(git config remote.$remote.tagopt)
		if [[ -z $tags_config ]]; then
		    echo "$fg_bold[yellow]Tags fetching is not configured for remote $fg_bold[magenta]${remote}$fg_bold[yellow]. Run $fg_bold[cyan]git configure-fetch-tags ${remote} $fg_bold[yellow]to fetch all tags automatically$reset_color"
		fi
	    done
	fi
    fi
}

function execute-git-command-in() {
    local directory=$1
    shift

    git -C ${directory} $@
}

function git-delete-branch() {
    local branch=$1
    local remote=${2:-origin}
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    git push $remote :$branch

    if [[ "$branch" == "$current_branch" ]]; then
	# TODO Use function param or get default branch??
	git checkout develop || git checkout master
    fi

    git branch -D $branch
}

function enable-forgit() {
    if [[ -o interactive ]]; then
	if [[ -a ~/.dziman-zsh/forgit/forgit.plugin.zsh ]]; then
            source ~/.dziman-zsh/forgit/forgit.plugin.zsh
	else
	    # TODO Add git clone?
	    # git://github.com/zsh-users/zsh-autosuggestions
	    echo "forgit not found. Clone from git://github.com/wfxr/forgit to ~/.dziman-zsh/forgit/"
	fi
    fi
}

add-zsh-hook chpwd check-tags-config

[[ -o interactive ]] && check-git-completion

enable-forgit
