#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Low level common functions
################################################################################

# Checks if command/app exist. Extracted to function so
# it could be easily switched from `command` to `which` ot to `hash` or to whatever is the best at the moment
function command-exists() {
  command -v $1 &>/dev/null
}
