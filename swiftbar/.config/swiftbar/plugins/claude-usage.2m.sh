#!/bin/bash
# <swiftbar.title>Claude usage</swiftbar.title>
# <swiftbar.desc>Claude 5-hour session and weekly usage in the menu bar.</swiftbar.desc>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# Fetches usage from the same (undocumented) endpoint Claude Code's /usage uses,
# with Claude Code's own login token from the keychain. It never refreshes the
# token itself (that would rotate Claude Code's login); when the token has
# expired it falls back to the cache that ~/.claude/statusline-command.sh writes.

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.swiftly/bin:$PATH"
api_cache="$HOME/.claude/usage-api-cache.json"
sl_cache="$HOME/.claude/rate-limits-cache.json"
now=$(date +%s)
note=""

# --- Fetch -------------------------------------------------------------------
creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
token=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
exp_ms=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.expiresAt // 0' 2>/dev/null)
if [ -z "$token" ]; then
  note="No Claude Code login found in keychain"
elif [ $(( exp_ms / 1000 )) -le "$now" ]; then
  note="Login token expired, start Claude Code to renew it"
else
  resp=$(curl -s -m 10 -w '\n%{http_code}' https://api.anthropic.com/api/oauth/usage \
    -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20")
  code=${resp##*$'\n'}; body=${resp%$'\n'*}
  if [ "$code" = 200 ] && printf '%s' "$body" | jq -e '.five_hour' >/dev/null 2>&1; then
    printf '%s' "$body" | jq -c --argjson now "$now" '{updated: $now, source: "api", data: .}' \
      > "$api_cache.$$" && mv -f "$api_cache.$$" "$api_cache"
  else
    note="Usage request failed (HTTP ${code:-none})"
  fi
fi

# --- Pick the freshest data --------------------------------------------------
# Normalise both sources to: updated, p5, r5, p7, r7 (resets as epoch seconds).
iso_to_epoch() { [ -n "$1" ] && date -j -u -f "%Y-%m-%dT%H:%M:%S" "${1:0:19}" +%s 2>/dev/null; }
to_epoch() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]] && echo "${1%.*}" || iso_to_epoch "$1"; }

a_upd=$(jq -r '.updated // 0' "$api_cache" 2>/dev/null || echo 0)
s_upd=$(jq -r '.updated // 0' "$sl_cache" 2>/dev/null || echo 0)
src=""
if [ "${a_upd:-0}" -gt 0 ] && [ "${a_upd:-0}" -ge "${s_upd:-0}" ]; then
  src=api; updated=$a_upd
  p5=$(jq -r '.data.five_hour.utilization // empty' "$api_cache")
  r5=$(to_epoch "$(jq -r '.data.five_hour.resets_at // empty' "$api_cache")")
  p7=$(jq -r '.data.seven_day.utilization // empty' "$api_cache")
  r7=$(to_epoch "$(jq -r '.data.seven_day.resets_at // empty' "$api_cache")")
elif [ "${s_upd:-0}" -gt 0 ]; then
  src=statusline; updated=$s_upd
  p5=$(jq -r '.rate_limits.five_hour.used_percentage // empty' "$sl_cache")
  r5=$(to_epoch "$(jq -r '.rate_limits.five_hour.resets_at // empty' "$sl_cache")")
  p7=$(jq -r '.rate_limits.seven_day.used_percentage // empty' "$sl_cache")
  r7=$(to_epoch "$(jq -r '.rate_limits.seven_day.resets_at // empty' "$sl_cache")")
fi

if [ -z "$src" ]; then
  echo "✳ –"; echo "---"; echo "${note:-No usage data yet} | color=gray"
  echo "Refresh | refresh=true"; exit 0
fi

# A window that has reset since the data was fetched is back at 0%.
[ -n "$r5" ] && [ "$r5" -le "$now" ] && p5=0
[ -n "$r7" ] && [ "$r7" -le "$now" ] && p7=0
[ -n "$p5" ] && p5=$(printf '%.0f' "$p5")
[ -n "$p7" ] && p7=$(printf '%.0f' "$p7")
age=$(( now - updated ))
stale=0; [ "$age" -gt 1800 ] && stale=1

# --- Colors ------------------------------------------------------------------
# green < 40 ≤ lime < 60 ≤ yellow < 70 ≤ orange < 80 ≤ red
hex_for() {
  if   [ "$1" -lt 40 ]; then echo "#34C759"
  elif [ "$1" -lt 60 ]; then echo "#A3D139"
  elif [ "$1" -lt 70 ]; then echo "#FFCC00"
  elif [ "$1" -lt 80 ]; then echo "#FF9500"
  else                       echo "#FF3B30"
  fi
}
fmt_dur() {
  local s=$1; [ "$s" -le 0 ] && { echo "now"; return; }
  local d=$(( s / 86400 )) h=$(( s % 86400 / 3600 )) m=$(( s % 3600 / 60 ))
  if [ "$d" -gt 0 ]; then echo "${d}d ${h}h"; elif [ "$h" -gt 0 ]; then echo "${h}h ${m}m"; else echo "${m}m"; fi
}

# --- Menu bar title: drawn as an image so each number gets its own color ---
# Reset time: whole hours under a day, whole days beyond that (rounded, min 1).
short_left() {
  local s=$(( $1 - now ))
  if [ "$s" -le 0 ]; then echo "0h"
  elif [ "$s" -lt 86400 ]; then local h=$(( (s + 1800) / 3600 )); echo "$(( h < 1 ? 1 : h ))h"
  else echo "$(( (s + 43200) / 86400 ))d"
  fi
}
appearance=${OS_APPEARANCE:-$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo Light)}
seg() { [ "$stale" = 1 ] && echo "~" || hex_for "$1"; }
parts=("✳ " "-")
if [ -n "$p5" ]; then
  parts+=("${p5}%" "$(seg "$p5")")
  [ -n "$r5" ] && parts+=(" ($(short_left "$r5"))" "~")
fi
[ -n "$p5" ] && [ -n "$p7" ] && parts+=("  ·  " "~")
if [ -n "$p7" ]; then
  parts+=("${p7}%" "$(seg "$p7")")
  [ -n "$r7" ] && parts+=(" ($(short_left "$r7"))" "~")
fi
renderer="$HOME/.config/swiftbar/bin/menubar-text"
# Build the renderer from its source on first run (or after the source changes).
if [ ! -x "$renderer" ] || [ "$renderer.swift" -nt "$renderer" ]; then
  swiftc=$(command -v swiftc || xcrun -f swiftc 2>/dev/null)
  [ -n "$swiftc" ] && "$swiftc" -O "$renderer.swift" -o "$renderer.tmp" 2>/dev/null \
    && mv -f "$renderer.tmp" "$renderer"
fi
if img=$("$renderer" "$appearance" "${parts[@]}" 2>/dev/null) && [ -n "$img" ]; then
  echo "| image=$img"
else  # renderer missing: plain text, colored by the higher of the two
  plain=""; for ((k=0; k<${#parts[@]}; k+=2)); do plain+="${parts[k]}"; done
  worst=$(( ${p5:-0} > ${p7:-0} ? ${p5:-0} : ${p7:-0} ))
  echo "$plain | color=$(hex_for "$worst")"
fi

# --- Dropdown ----------------------------------------------------------------
echo "---"
if [ -n "$p5" ]; then
  echo "Current session (5h): ${p5}% | color=$(hex_for "$p5")"
  [ -n "$r5" ] && echo "--Resets in $(fmt_dur $(( r5 - now ))) ($(date -r "$r5" '+%a %H:%M'))"
fi
if [ -n "$p7" ]; then
  echo "Weekly (7d): ${p7}% | color=$(hex_for "$p7")"
  [ -n "$r7" ] && echo "--Resets in $(fmt_dur $(( r7 - now ))) ($(date -r "$r7" '+%a %H:%M'))"
fi
if [ "$src" = api ]; then
  # Model-specific weekly limits, e.g. "Weekly (Fable)".
  jq -r '.data.limits[]? | select(.kind == "weekly_scoped") |
         "\(.scope.model.display_name // .scope.surface // "scoped")\t\(.percent)"' "$api_cache" 2>/dev/null |
  while IFS=$'\t' read -r name pct; do
    echo "Weekly ($name): ${pct}% | color=$(hex_for "$pct")"
  done
fi
echo "---"
[ -n "$note" ] && echo "⚠︎ $note | color=#FF9500 size=12"
if [ "$age" -lt 60 ]; then upd="just now"; else upd="$(fmt_dur "$age") ago"; fi
echo "Updated $upd (via $src) | color=gray size=11"
echo "Open usage page | href=https://claude.ai/settings/usage"
echo "Refresh | refresh=true"
