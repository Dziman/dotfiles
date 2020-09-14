#!/bin/zsh
# Author: Dziman <dziman.by@gmail.com>
################################################################################
# navi (https://github.com/denisidoro/navi)
################################################################################

# custom cheatsheets location
export NAVI_PATH="$HOME/.local/share/navi"

function _call_navi() {
  local selected
  if [ -n "$LBUFFER" ]; then
    if selected="$(printf "%s" "$(navi --print --fzf-overrides '--no-select-1' --query "${LBUFFER}" </dev/tty)")"; then
      LBUFFER="$selected"
    fi
  else
    if selected="$(printf "%s" "$(navi --print </dev/tty)")"; then
      LBUFFER="$selected"
    fi
  fi
  zle redisplay
}

function init-navi-shell-widget() {
    # TODO check if std widget changed
    local current_std_widget=$(navi widget zsh)
    local known_std_widget=$(cat <<\EOF
#!/usr/bin/env zsh

_call_navi() {
  local selected
  if [ -n "$LBUFFER" ]; then
    if selected="$(printf "%s" "$(navi --print --no-autoselect query "${LBUFFER}" </dev/tty)")"; then
      LBUFFER="$selected"
    fi
  else
    if selected="$(printf "%s" "$(navi --print </dev/tty)")"; then
      LBUFFER="$selected"
    fi
  fi
  zle redisplay
}

zle -N _call_navi

bindkey '^g' _call_navi
EOF
)

    if [[ ${current_std_widget} !=  ${known_std_widget} ]]; then
      echo "navi widget changed. Please check ~/.dziman-zsh/590_navi.enabled.zsh"
    fi

    zle -N _call_navi

    bindkey '^n' _call_navi
}

if [[ -o interactive ]] && which navi &>/dev/null; then
    init-navi-shell-widget
fi
