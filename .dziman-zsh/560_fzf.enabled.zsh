if [[ -o interactive ]] && which fzf &>/dev/null; then
    ## Auto-completion
    # ---------------
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" 2> /dev/null

    # Key bindings
    # ------------
    source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
fi
