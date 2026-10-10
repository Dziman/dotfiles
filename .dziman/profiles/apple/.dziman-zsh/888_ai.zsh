#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# AI tools used at work
################################################################################

# kata: opt out of anonymous PostHog telemetry. The daemon otherwise posts
# 'daemon_started' on every start and a daily 'daemon_active' heartbeat to
# us.i.posthog.com, and any kata command auto-starts a daemon.
export KATA_TELEMETRY_ENABLED=0

# kata: one 'work' project for every repo; always pass --project.
# After `brew upgrade kata`:
#   launchctl kickstart -k gui/$UID/io.kenn.kata.daemon
#   launchctl kickstart -k gui/$UID/io.kenn.kata.mcp
#   kata completion zsh > ~/.zsh/site-functions/_kata
alias k='kata --project work'

alias omp='VISUAL="emacsclient -f $HOME/.emacs.d/server/omp -t" omp'
