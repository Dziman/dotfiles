#!/bin/bash
# Renders one row per running subagent: icon type [model|effort] description
# The agent-model-tag PreToolUse hook bakes "[subagent_type] " onto the front
# and "-<modelslug>"/"-inherit" onto the end of the description at launch
# time. Parse both back out here; drop the model tag once the live model
# field resolves and matches, so it doesn't show twice.
input=$(cat)
echo "$input" | jq -c '
  (.tasks // [] | if type == "array" then .[] else empty end) |
  ((.description // .label // "agent") | gsub("[\\x00-\\x1f]"; " ")) as $d |
  (.model // "") as $m |
  ((.effort // "") | tostring) as $eff |
  (.status // "unknown") as $status |
  ($d | capture("^\\[(?<type>[^\\]]+)\\]\\s?(?<rest>.*)$")? // {type: "agent", rest: $d}) as $parsed |
  (if $m != "" then ($parsed.rest | sub("-[A-Za-z0-9]+$"; "")) else $parsed.rest end) as $clean |
  ({running: "▶", in_progress: "▶", pending: "◷", queued: "◷", completed: "✓", done: "✓", success: "✓", failed: "✗", error: "✗", cancelled: "■"}[$status] // "•") as $icon |
  (if $m == "" then "resolving..." else ($m | if startswith("claude-") then .[7:] else . end) end) as $mshort |
  ({low: "🪁", medium: "🛩️", high: "✈️", xhigh: "🛰️", max: "🚀"}[$eff] // $eff) as $effIcon |
  (if $m == "" or $eff == "" then $mshort else "\($mshort)|\($effIcon)" end) as $tag |
  {id, content: ("\($icon) \($parsed.type) [\($tag)] \($clean)")}
' 2>/dev/null
