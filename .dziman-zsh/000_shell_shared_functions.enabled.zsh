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

# Show confirmation 'dialog'. In fancy way if `gum` installed otherwise use shell built-in selection
# TODO Add named argements? Like `-m "Are you sure" -y "Yes" -n "No"` or `--message "Are you sure" --yes-caption "Yes" --no-caption "No"
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash`
function show-confirmation() {
  local confirmation_question=$1
  local confirm_option=$2
  local cancel_option=$3

  if command-exists gum; then
    local -a gum_args=()
    local confirmation_timeout=$4
    local default_selection=$5

    gum_args+=(confirm "$confirmation_question")
    gum_args+=(--selected.background "101")
    gum_args+=(--affirmative "$confirm_option")
    gum_args+=(--negative "$cancel_option")

    if [ -n "${confirmation_timeout}" ]; then
      gum_args+=(--timeout "$confirmation_timeout") # TODO Check why this option doesn't work
    fi

    if [ -n "${default_selection}" ]; then
      gum_args+=(--default="$default_selection")
    fi

    gum_args+=(--no-show-help)

    gum "${gum_args[@]}"
  else
    local -a answers=("$confirm_option" "$cancel_option")
    echo "$confirmation_question"
    select answer in $answers; do
      case $answer in
        "$confirm_option")
          return 0
          ;;
        "$cancel_option")
          return 1
          ;;
        *) echo "Invalid selection" ;;
      esac
    done
  fi

}
