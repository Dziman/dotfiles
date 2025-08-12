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

  setopt localoptions rmstarsilent
  rm -r  ~/.jenv/versions/*

  local brew_prefix=$(brew --prefix)
  local -a installed_openjdks=($(gls -d /Library/Java/JavaVirtualMachines/*jdk-[0-9][0-9].jdk))

  for openjdk_root in $installed_openjdks; do
      if [[ -L "$openjdk_root" ]]; then
          jenv add $openjdk_root/Contents/Home/ > /dev/null
      fi
  done

  jenv versions
}
