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
  if [ -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git ]; then
    echo "${fg_bold[yellow]}git completion detected while better alternative exists$reset_color"
  fi
}

function fix-git-completion() {
  if [ -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git ]; then
    show-confirmation "git completion detected while better alternative exists. Do you want to delete it?" "Yes" "No" && \
      rm $HOMEBREW_PREFIX/share/zsh/site-functions/_git
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
    local forgit_zsh_plugin="${HOMEBREW_PREFIX}/opt/forgit/share/forgit/forgit.plugin.zsh"

    if [[ -e  $forgit_zsh_plugin ]]; then
      export FORGIT_LOG_FORMAT="%C(red)%h%Creset - %C(green)(%ci%x08%x08%x08%x08%x08%x08) %C(bold blue)%<(20)%an%Creset %C(yellow)%d%Creset %s"
      export FORGIT_FZF_DEFAULT_OPTS="--reverse --preview-window bottom"
      source "$forgit_zsh_plugin"
    else
      echo "forgit not found. Please install it `brew install forgit`"
    fi
  fi
}

add-zsh-hook chpwd check-tags-config

[[ -o interactive ]] && check-git-completion

enable-forgit
