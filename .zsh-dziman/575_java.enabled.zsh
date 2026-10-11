#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

if [[ -o interactive ]] then
   # jenv: the cheap part of `jenv init` up front, the rest (~0.15 s: rehash, plugins)
   # on the first `jenv` call. After installing a JDK run `jenv rehash` once.
   if command-exists jenv; then
      export PATH="${JENV_ROOT:-$HOME/.jenv}/shims:${PATH}"
      export JENV_SHELL=zsh
      export JENV_LOADED=1
      unset JAVA_HOME JDK_HOME
      source "$HOMEBREW_PREFIX/opt/jenv/libexec/completions/jenv.zsh"
      function jenv() {
         unfunction jenv
         eval "$(command jenv init - zsh)"
         jenv "$@"
      }
   fi

   # init gradle completion. Temporary(?) workaround as putting it into $fpath has no effect
   if [[ -e $HOMEBREW_PREFIX/share/zsh/site-functions/_gradle ]]; then source $HOMEBREW_PREFIX/share/zsh/site-functions/_gradle 1>&2 2>/dev/null; fi

fi

function refresh-jenv() {
  command-exists jenv || return 1

  setopt localoptions rmstarsilent
  rm -r ~/.jenv/versions/*

  # Homebrew openjdk formulae
  local openjdk_root
  for openjdk_root in $HOMEBREW_PREFIX/Cellar/openjdk*(N/); do
    local openjdk_version_dir=$(gls $openjdk_root | head -1)
    jenv add $openjdk_root/$openjdk_version_dir/libexec/openjdk.jdk/Contents/Home/ > /dev/null
  done

  # JDKs installed as macOS packages (e.g. Apple JDK casks)
  local jdk_root
  for jdk_root in /Library/Java/JavaVirtualMachines/*.jdk(N); do
    [[ -d $jdk_root/Contents/Home ]] && jenv add $jdk_root/Contents/Home/ > /dev/null
  done

  jenv versions
}
