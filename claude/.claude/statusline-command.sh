#!/bin/bash
# Minimal status line: model name, reasoning effort, context used percentage.
input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
if [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

out="${model:-Claude}"
[ -n "$effort" ] && out="$out ($effort)"
if [ -n "$used" ]; then
  out="$out | ctx $(printf '%.0f' "$used")%"
fi
# Rate limits appear only for Pro/Max, after the first API response.
five_h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
right=""
[ -n "$five_h" ] && right="5h $(printf '%.0f' "$five_h")%"
[ -n "$week" ] && right="${right:+$right | }7d $(printf '%.0f' "$week")%"

# Right-align the rate limits using the terminal width Claude Code passes in
# COLUMNS; the margin absorbs the status line's own horizontal padding.
margin=4
cols=${COLUMNS:-0}
if [ -n "$right" ]; then
  gap=$(( cols - margin - ${#out} - ${#right} ))
  if [ "$gap" -ge 2 ]; then
    out="$out$(printf '%*s' "$gap" '')$right"
  else
    out="$out | $right"
  fi
fi
printf '%s\n' "$out"
