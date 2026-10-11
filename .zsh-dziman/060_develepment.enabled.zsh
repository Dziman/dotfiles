#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# General development tools
################################################################################

# anyenv initialization
if [[ -o interactive ]] && command-exists anyenv; then eval "$(anyenv init - zsh)"; fi

# node env
if command-exists fnm; then
  eval "$(fnm env --use-on-cd --shell zsh)"
else
  # TODO: replace nvm with fnm on this machine
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"  # This loads nvm
  [[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion" ]] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion
fi

# Add LLVM to path
export PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$PATH"

# Rust
export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
