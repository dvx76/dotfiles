#!/bin/bash
# Minimal status line: directory, git branch, model name, reasoning effort,
# context used percentage, and rate limits on the right.
# Colors follow Claude Code's default dark theme palette (24-bit color).
input=$(cat)

# Palette
reset=$'\e[0m'
dim=$'\e[2m'
c_dir=$'\e[38;2;177;185;249m'       # soft blue
c_branch=$'\e[38;2;175;135;255m'    # violet
c_model=$'\e[1;38;2;215;119;87m'    # Claude orange, bold
c_ok=$'\e[38;2;78;186;101m'         # green
c_warn=$'\e[38;2;255;193;7m'        # amber
c_crit=$'\e[38;2;255;107;128m'      # red

# Pick a color for a usage percentage: green < 50, amber < 80, red otherwise.
pct_color() {
  if [ "$1" -lt 50 ]; then printf '%s' "$c_ok"
  elif [ "$1" -lt 80 ]; then printf '%s' "$c_warn"
  else printf '%s' "$c_crit"
  fi
}

# Build each side twice: plain text (for width math) and colored text (for display).
plain=""
out=""
add() { # add <plain> <colored>
  plain="$plain$1"
  out="$out$2"
}
sep=" | "
sep_c="$dim | $reset"

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=""
[ -n "$dir" ] && branch=$(git -C "$dir" branch --show-current 2>/dev/null)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
if [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$dir" ]; then
  short="${dir/#$HOME/\~}"
  add "$short" "$c_dir$short$reset"
  [ -n "$branch" ] && add " ($branch)" " $dim($reset$c_branch$branch$reset$dim)$reset"
  add "$sep" "$sep_c"
fi
m="${model:-Claude}"
add "$m" "$c_model$m$reset"
[ -n "$effort" ] && add " ($effort)" " $dim($effort)$reset"
if [ -n "$used" ]; then
  p=$(printf '%.0f' "$used")
  add "${sep}ctx $p%" "${sep_c}${dim}ctx$reset $(pct_color "$p")$p%$reset"
fi

# Rate limits appear only for Pro/Max, after the first API response.
five_h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
right=""
right_c=""
if [ -n "$five_h" ]; then
  p=$(printf '%.0f' "$five_h")
  right="5h $p%"
  right_c="${dim}5h$reset $(pct_color "$p")$p%$reset"
fi
if [ -n "$week" ]; then
  p=$(printf '%.0f' "$week")
  right="${right:+$right$sep}7d $p%"
  right_c="${right_c:+$right_c$sep_c}${dim}7d$reset $(pct_color "$p")$p%$reset"
fi

# Right-align the rate limits using the terminal width Claude Code passes in
# COLUMNS; the margin absorbs the status line's own horizontal padding.
margin=4
cols=${COLUMNS:-0}
if [ -n "$right" ]; then
  gap=$(( cols - margin - ${#plain} - ${#right} ))
  if [ "$gap" -ge 2 ]; then
    out="$out$(printf '%*s' "$gap" '')$right_c"
  else
    out="$out$sep_c$right_c"
  fi
fi
printf '%s\n' "$out"
