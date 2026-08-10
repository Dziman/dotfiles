#!/bin/bash
set -euo pipefail

payload=$(cat)

model=$(jq -r '.tool_input.model // ""' <<<"$payload")
subagent_type=$(jq -r '.tool_input.subagent_type // "agent"' <<<"$payload")
desc=$(jq -r '.tool_input.description // "agent"' <<<"$payload")

# Forks always run on the parent model; a passed `model` is ignored for them.
[[ $subagent_type == fork ]] && model=""

if [[ -z $model ]]; then
  # Frontmatter or parent decides — unknowable here, so say so.
  suffix=inherit
else
  # Strip to plain alnum: claude-sonnet-5 -> claudesonnet5.
  suffix=$(tr -cd '[:alnum:]' <<<"$model")
fi

new_desc=$desc

# Prefix with [subagent_type] once.
if [[ $new_desc != \[*\]\ * ]]; then
  new_desc="[$subagent_type] $new_desc"
fi

# Suffix with -<model tag> once.
if [[ -n $suffix && $new_desc != *"-$suffix" ]]; then
  # description is capped, so trim the task part, not the tags.
  max_base=$((64 - ${#suffix} - 1))
  (( max_base < 0 )) && max_base=0
  [[ ${#new_desc} -gt $max_base ]] && new_desc=${new_desc:0:$max_base}
  new_desc="${new_desc%-}-$suffix"
fi

[[ $new_desc == "$desc" ]] && exit 0

jq -c --arg desc "$new_desc" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: (.tool_input + {description: $desc})}}' \
  <<<"$payload"
