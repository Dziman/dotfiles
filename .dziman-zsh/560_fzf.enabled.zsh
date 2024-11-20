if [[ -o interactive ]] && command-exists fzf; then
  eval "$(fzf --zsh)"

  if command-exists bat; then

    function dz-fzf() {
      fzf --ansi \
          --pointer "▶︎" \
          --marker "✓" \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --bind "ctrl-k:execute(echo {1} | tr -d '\n' | pbcopy)" \
          --bind "ctrl-o:execute(echo {1})" \
          "${@}"
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
          dz-fzf --preview "bat --color=always {1}" \
                 --preview-window "up,60%,border-bottom,+0+3/3,~3" \
                 --bind "alt-enter:become(zsh -i -c 'idea {1}')" \
                 --bind "enter:become(zsh -i -c 'edit {1}')"
      }
    fi

  fi

fi
