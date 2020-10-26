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
    if [ -f /usr/local/share/zsh/site-functions/_git ]; then
        echo "$fg_bold[yellow]git completion detected while better alternative exists$reset_color"
    fi
}

function fix-git-completion() {
    if [ -f /usr/local/share/zsh/site-functions/_git ]; then
        echo "git completion detected while better alternative exists"
        PS3="Do you want delete it? "
        answers=("Yes" "No")
        select answer in "${answers[@]}"
        do
            case $answer in
            "Yes")
                 rm /usr/local/share/zsh/site-functions/_git
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

add-zsh-hook chpwd check-tags-config

[[ -o interactive ]] && check-git-completion
