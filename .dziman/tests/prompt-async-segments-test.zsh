#!/bin/zsh
# Tests for async right-prompt segments in ~/.zsh-dziman/910_prompt.enabled.zsh.
# Each test drives an interactive zsh in a pseudo-terminal, with jenv-status
# replaced by a test segment, and saves the right prompt the shell is showing.
# Run: zsh ~/.dziman/tests/prompt-async-segments-test.zsh
set -u
zmodload zsh/zpty

prompt_file=${0:A:h}/../../.zsh-dziman/910_prompt.enabled.zsh
tmp=$(mktemp -d)
trap 'zpty -d shell 2>/dev/null; rm -rf "$tmp"' EXIT
cd "$tmp"
failed=0
assert() { # assert <description> <command...>
  local desc=$1; shift
  if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi
}
not() { ! "$@"; }

# fixture: an interactive shell with the prompt file loaded
# <segment-body>: body of the jenv-status test segment
start_shell() {
  zpty -d shell 2>/dev/null
  rm -f "$tmp"/rprompt-*(N) "$tmp"/slow
  cat > "$tmp/.zshrc" <<EOF
typeset -A icons
command-exists() { false }
source $prompt_file
jenv-status() { $1 }
EOF
  zpty shell "ZDOTDIR=$tmp HOMEBREW_PREFIX= TERM=xterm-256color zsh -d -i"
}

# The shell blocks on terminal mode switches until its output is read, so every
# wait keeps reading it. zpty -r without a pattern blocks until a newline.
drain_output() { local out; while zpty -rt shell out '*'; do :; done; }
# <seconds>
let_shell_run() {
  repeat $(( $1 * 10 )) { drain_output; sleep 0.1; }
}

# <name>: type a command that saves the current right prompt to rprompt-<name>
save_rprompt() {
  zpty -w shell "print -r -- \"\$RPS1\" > $tmp/rprompt-$1"
  local tries=0
  while [[ ! -s "$tmp/rprompt-$1" ]] && (( tries++ < 50 )); do drain_output; sleep 0.1; done
}
rprompt_shows() { grep -q -- "$2" "$tmp/rprompt-$1"; } # <name> <text>
# fails, like rprompt_shows, when the right prompt was never saved
rprompt_lacks() { [[ -s "$tmp/rprompt-$1" ]] && not rprompt_shows "$@"; }

start_shell 'sleep 1; print -n SEGMENT'
save_rprompt first
assert "a slow segment does not hold back the prompt" rprompt_lacks first SEGMENT

start_shell 'sleep 0.3; print -n SEGMENT'
let_shell_run 1.5
save_rprompt first
assert "a slow segment shows once it finishes" rprompt_shows first SEGMENT

start_shell "[[ -e $tmp/slow ]] && sleep 1; print -n SEGMENT"
let_shell_run 1
touch "$tmp/slow"
save_rprompt first
save_rprompt second
assert "a new prompt starts without the previous prompt's output" rprompt_lacks second SEGMENT

mkdir "$tmp/slowdir" "$tmp/fastdir"
start_shell '[[ $PWD == */slowdir ]] && sleep 1; print -n ${PWD:t}'
zpty -w shell "cd $tmp/slowdir"
zpty -w shell "cd $tmp/fastdir"
let_shell_run 2
save_rprompt first
assert "a job from an earlier prompt does not overwrite the current one" \
  rprompt_lacks first slowdir

exit $failed
