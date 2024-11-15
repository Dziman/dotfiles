if [[ -o interactive ]] && command-exists fzf; then
  eval "$(fzf --zsh)"

  if command-exists rg && command-exists bat; then
    function rgf() {
      rg --color=always --line-number --no-heading --ignore-case "${*:-}" |
        fzf --ansi \
            --pointer ▶︎ \
            --marker ✓ \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview "bat --color=always {1} --highlight-line {2}" \
            --preview-window "up,60%,border-bottom,+{2}+3/3,~3" \
            --bind "alt-enter:become(zsh -i -c 'ideal {2} {1}')" \
            --bind "enter:become(zsh -i -c 'edit +{2} {1}')"
    }
  fi
  
fi

