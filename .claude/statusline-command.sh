#!/usr/bin/env zsh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
display_path="${cwd/#$home/~}"

# Powerline-style status line using ANSI 256-color codes
# Segment 1: bg=246 (light gray), fg=10 (bright green) — icon + path
# Segment 2: bg=66 (teal), fg=10 (bright green) — context usage (if available)
# Tip: fg=66 on default bg — closing arrow

if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  # Color the context segment based on usage level
  if [ "$used_int" -ge 90 ]; then
    ctx_bg=160   # red
    ctx_fg=231   # white
  elif [ "$used_int" -ge 75 ]; then
    ctx_bg=208   # orange
    ctx_fg=232   # near-black
  else
    ctx_bg=66    # teal (matches path segment)
    ctx_fg=10    # bright green
  fi
  printf "\e[38;5;246m\e[48;5;246m\e[38;5;10m  \e[38;5;246m\e[48;5;66m\e[38;5;10m %s \e[38;5;66m\e[48;5;%sm\e[38;5;%sm %s%% \e[38;5;%sm\e[49m\e[39m" \
    "$display_path" "$ctx_bg" "$ctx_fg" "$used_int" "$ctx_bg"
else
  printf "\e[38;5;246m\e[48;5;246m\e[38;5;10m  \e[38;5;246m\e[48;5;66m\e[38;5;10m %s \e[38;5;66m\e[49m\e[39m" "$display_path"
fi
