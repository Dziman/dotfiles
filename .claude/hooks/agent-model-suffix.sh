#!/usr/bin/env bash
# PreToolUse hook (matcher: Agent).
#
# Makes the model a subagent runs on visible in the UI by appending it to the
# agent's `name`, e.g. `code-review` + model:sonnet -> `code-review-sonnet5`.
# The `description` field is not rendered, and `name` is short enough that it is
# never truncated, so `name` is the only reliable channel for this label.
#
# When the Agent call omits `model` the effective model comes from the agent
# definition's frontmatter or is inherited from the parent session, and the hook
# has no way to see which. Those calls are labelled `-inherit` rather than
# guessed at, so an unlabelled dispatch never reads as a known model.
#
# The label mirrors the `model` parameter verbatim. Aliases like `sonnet` float
# to the current generation, and only the server knows which — so `-sonnet`, not
# `-sonnet5`, which would silently lie the day the next Sonnet ships. Pass a full
# model id when the label needs to name a version.
set -euo pipefail

payload=$(cat)

model=$(jq -r '.tool_input.model // ""' <<<"$payload")
subagent_type=$(jq -r '.tool_input.subagent_type // ""' <<<"$payload")

# Forks always run on the parent model; a passed `model` is ignored for them.
[[ $subagent_type == fork ]] && model=""

if [[ -z $model ]]; then
  # Frontmatter or parent decides — unknowable here, so say so.
  suffix=inherit
else
  # Strip to the characters `name` accepts: claude-sonnet-5 -> claudesonnet5.
  suffix=$(tr -cd '[:alnum:]' <<<"$model")
fi
[[ -n $suffix ]] || exit 0

name=$(jq -r '.tool_input.name // "agent"' <<<"$payload")
[[ $name == *-"$suffix" ]] && exit 0

# `name` is capped at 64 chars, so trim the task part, not the label.
max_base=$((64 - ${#suffix} - 1))
[[ ${#name} -gt $max_base ]] && name=${name:0:$max_base}
name=${name%-}

jq -c --arg name "$name-$suffix" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: (.tool_input + {name: $name})}}' \
  <<<"$payload"
