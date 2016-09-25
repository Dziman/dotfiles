#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Java specific
################################################################################

# disable annoying java icons in doc TODO It seems Java ignores this
export OSX_JAVAOPTS='-Dapple.awt.UIElement=true -Djava.awt.headless=true'

# jenv initialization
if which jenv > /dev/null; then eval "$(jenv init -)"; fi
