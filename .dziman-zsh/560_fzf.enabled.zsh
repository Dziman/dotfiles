if which fzf &>/dev/null; then

  FZF_FOLDER=$(which fzf | xargs greadlink -f | sed 's/\/bin\/fzf$//')

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$FZF_FOLDER/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "$FZF_FOLDER/shell/key-bindings.zsh"

fi

