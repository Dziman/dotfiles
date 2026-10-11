#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# AI specific settings
################################################################################

export OPENROUTER_API_KEY="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"

alias claude="EDITOR=claude-editor claude"

# omp: add the machine profile's config overlay (models, presets, services) when the profile has one
function omp() {
  local overlay=~/.dziman/profile/.omp/agent/config.yml
  if [[ -r $overlay ]]; then
    command omp --config "$overlay" "$@"
  else
    command omp "$@"
  fi
}
