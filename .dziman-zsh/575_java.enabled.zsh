#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

if [[ -o interactive ]] then
   # jenv initialization
   if command-exists jenv; then eval "$(jenv init - zsh)"; fi

   # init gradle completion. Temporary(?) workaround as putting it into $fpath has no effect
   if [[ -e $HOMEBREW_PREFIX/share/zsh/site-functions/_gradle ]]; then source $HOMEBREW_PREFIX/share/zsh/site-functions/_gradle 1>&2 2>/dev/null; fi

fi

function refresh-jenv() {
  command-exists jenv || return 1

  setopt localoptions rmstarsilent
  rm -r ~/.jenv/versions/*

  local -a installed_openjdks=($(gls -d $HOMEBREW_PREFIX/Cellar/openjdk*))

  for openjdk_root in $installed_openjdks; do
    local openjdk_version_dir=$(gls $openjdk_root | head -1)
    jenv add $openjdk_root/$openjdk_version_dir/libexec/openjdk.jdk/Contents/Home/ > /dev/null
  done

  jenv versions
}
