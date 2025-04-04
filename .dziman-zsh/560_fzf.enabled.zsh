#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# fzf customizations
################################################################################
if [[ -o interactive ]] && command-exists fzf; then

  eval "$(fzf --zsh)"

  # fzf wrapper with some common args
  # `zsh -i -c` should be used in bindings to allow functions (see `rgf`). Negative side effect: some performance impact in form of delay before command executed
  function dz-fzf() {
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --pointer ▶︎ \
        --marker ✓ \
        "$@"
  }

  # TODO Review for de-duplication
  if command-exists rg; then
    function rgf() {
      rg --color=always --line-number --no-heading --ignore-case "${*:-}" |
        dz-fzf --delimiter : \
               --preview "bat --color=always {1} --highlight-line {2}" \
               --preview-window "up,60%,border-bottom,+{2}+3/3,~3" \
               --bind "alt-enter:become(zsh -i -c 'ideal {2} {1}')" \
               --bind "enter:become(zsh -i -c 'edit +{2} {1}')"
    }
  fi

  if command-exists fd; then
    function fdf() {
      fd "${*:-}" |
        dz-fzf --delimiter : \
               --preview "bat --color=always {1}" \
               --preview-window "up,60%,border-bottom,+0+3/3,~3" \
               --bind "alt-enter:become(zsh -i -c 'idea {1}')" \
               --bind "enter:become(zsh -i -c 'edit {1}')"
    }
  fi

fi
