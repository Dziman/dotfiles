#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

alias mvnp='mvn -T1.5C'

# jenv initialization
if [[ -o interactive ]] && command-exists jenv; then eval "$(jenv init - zsh)"; fi

function refresh-jenv() {
  command-exists jenv || return 1

  local -a jenv_versions=($(jenv completions local))
  jenv_versions=("${(@)jenv_versions:#system}") # remove 'system' entry from versions list
  jenv_versions=("${(@)jenv_versions:#--unset}") # remove '--unset' entry from versions list

  for jenv_version in $jenv_versions; do
    jenv remove $jenv_version > /dev/null
  done

  local brew_prefix=$(brew --prefix)
  local -a installed_openjdks=($(gls -d /Library/Java/JavaVirtualMachines/*jdk))

  for openjdk_root in $installed_openjdks; do
      if [[ -L "$openjdk_root" ]]; then
          jenv add $openjdk_root/Contents/Home/ > /dev/null
      fi
  done

  jenv versions
}
