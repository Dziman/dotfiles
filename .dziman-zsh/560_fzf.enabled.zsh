if [[ -o interactive ]] && command-exists fzf; then
  eval "$(fzf --zsh)"

  # TODO Check other utils installed
  function rge() {
    rg --color=always --line-number --no-heading --ignore-case "${*:-}" |
    fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become(emacsclient --tty +{2} {1})' # TODO Find a way to use aliases, functions defined in my scripts
  }

  # FIXME Remove duplication
  function rgi() {
    rg --color=always --line-number --no-heading --ignore-case "${*:-}" |
    fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become("/Applications/IntelliJ IDEA 2024.x EAP.app/Contents/MacOS/idea" --line {2} {1})' # TODO Find a way to use aliases, functions defined in my scripts
  }
fi

