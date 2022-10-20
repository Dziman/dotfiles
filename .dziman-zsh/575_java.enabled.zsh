#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

# jenv initialization
if [[ -o interactive ]] && command -v jenv > /dev/null; then eval "$(jenv init - zsh)"; fi

function refresh-jenv() {
  command -v jenv > /dev/null || return 1

  local -a jenv_versions=($(jenv completions local))
  jenv_versions=("${(@)jenv_versions:#system}") # remove 'system' entry from versions list
  jenv_versions=("${(@)jenv_versions:#--unset}") # remove '--unset' entry from versions list

  for jenv_version in $jenv_versions; do
    jenv remove $jenv_version > /dev/null
  done

  local brew_prefix=$(brew --prefix)
  local -a installed_openjdks=($(gls -d $brew_prefix/Cellar/openjdk*))

  for openjdk_root in $installed_openjdks; do
    local openjdk_version_dir=$(gls $openjdk_root | head -1)
    jenv add $openjdk_root/$openjdk_version_dir/libexec/openjdk.jdk/Contents/Home/ > /dev/null
  done

  jenv versions
}
