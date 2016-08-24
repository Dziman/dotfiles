#!/bin/zsh

function fix-git-completion() {
    # Fix git completion after git updated by brew: remove _git site function
    rm /usr/local/share/zsh/site-functions/_git
}

function install-dotfiles() {
    # Install dotfiles (tool to manage config files in home dir)
    pip install dotfiles
}
