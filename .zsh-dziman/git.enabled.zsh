#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# GIT specific
################################################################################

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

check-git-completion
