#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# Misc helper functions
################################################################################

function print-color-palette() {
  for i in {0..255} ; do
    printf "\x1b[38;5;${i}m%3d " "${i}"
      if (( $i == 15 )) || (( $i > 15 )) && (( ($i-15) % 12 == 0 )); then
        echo;
      fi
  done
}
