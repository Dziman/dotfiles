#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Bulk git commands across the Apple repos
################################################################################

function execute-git-in-dirs() {
  local dirs_array_name=$1
  shift

  for directory in ${(P)${dirs_array_name}}; do
    echo "$fg[green]--> Executing command in $(basename ${directory})$reset_color"

    execute-git-command-in $directory $@ || show-confirmation "Error executing git command. Do you want proceed in other repos?" "Yes" "No" 2s true || break
  done

}
