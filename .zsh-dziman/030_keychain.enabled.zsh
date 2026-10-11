#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# macOS Keychain
################################################################################

# An SSH login leaves the login Keychain locked, so tools that keep credentials
# there (Claude Code's MCP sign-ins) fail. Unlock it once; tmux panes started
# from the same SSH login share the unlock, so later panes skip the prompt.
if [[ -n $SSH_CONNECTION ]] && ! security show-keychain-info login.keychain-db >/dev/null 2>&1; then
  security unlock-keychain login.keychain-db
fi
