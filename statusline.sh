#!/usr/bin/env bash
# cc-statusline — Claude Code status line: Context %, 5h/7d rate limits, model, cwd.
# Reads status JSON from stdin (Claude Code contract), prints one line.
# No dependencies beyond jq. Falls back to session cost if rate_limits
# is absent (API-key billing instead of Pro/Max OAuth).

set -euo pipefail

no_header=0
for arg in "$@"; do
  case "$arg" in
    --no-header) no_header=1 ;;
  esac
done

json="$(cat)"

# --- colors -----------------------------------------------------------
RESET=$'\033[0m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[91m'   # bright red — dark red is unreadable on dark terminals

color_for() {
  # $1 = percentage (integer). green < 50, yellow < 80, red >= 80
  local pct="$1"
  if   (( pct >= 80 )); then echo "$RED"
  elif (( pct >= 50 )); then echo "$YELLOW"
  else                        echo "$GREEN"
  fi
}

clamp_pct() {
  # $1 = integer percentage -> clamped to [0, 100]. Upstream can send
  # slightly-off values (e.g. 134.7 or -5); the displayed label shouldn't
  # visually contradict the bar, which is already clamped for rendering.
  local pct="$1"
  if   (( pct > 100 )); then echo 100
  elif (( pct < 0 ));   then echo 0
  else                       echo "$pct"
  fi
}

bar() {
  # $1 = percentage, $2 = width in chars
  local pct="$1" width="${2:-10}"
  local filled=$(( pct * width / 100 ))
  if (( filled > width )); then filled=$width; fi
  local empty=$(( width - filled ))
  # bash's printf runs its format at least once even with zero args,
  # so guard the zero case explicitly instead of relying on seq being empty.
  if (( filled > 0 )); then printf '%0.s▓' $(seq 1 "$filled"); fi
  if (( empty  > 0 )); then printf '%0.s░' $(seq 1 "$empty"); fi
}

fmt_reset() {
  # $1 = unix epoch seconds -> "2h30m" until reset
  local resets_at="$1" now secs h m
  now=$(date +%s)
  secs=$(( resets_at - now ))
  (( secs < 0 )) && secs=0
  h=$(( secs / 3600 ))
  m=$(( (secs % 3600) / 60 ))
  if (( h > 0 )); then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# --- parse --------------------------------------------------------------
model=$(jq -r '.model.display_name // "Claude"' <<<"$json")
cwd=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$json")
dirname=$(basename -- "$cwd" 2>/dev/null || echo "")

ctx_pct=$(jq -r '.context_window.used_percentage // 0' <<<"$json")
ctx_pct=${ctx_pct%.*}   # integer truncate
ctx_pct=$(clamp_pct "$ctx_pct")

has_rate_limits=$(jq -r 'if .rate_limits then "yes" else "no" end' <<<"$json")

segments=()

# Directory + model (suppressed with --no-header, e.g. when a combining
# script already renders its own dirname/model and only wants the gauges)
if [[ "$no_header" -eq 0 ]]; then
  [[ -n "$dirname" ]] && segments+=("${DIM}${dirname}${RESET}")
  segments+=("${DIM}${model}${RESET}")
fi

# Context bar
ctx_color=$(color_for "$ctx_pct")
segments+=("Context ${ctx_color}$(bar "$ctx_pct" 8) ${ctx_pct}%${RESET}")

if [[ "$has_rate_limits" == "yes" ]]; then
  five_pct=$(jq -r '.rate_limits.five_hour.used_percentage // 0' <<<"$json")
  five_pct=${five_pct%.*}
  five_pct=$(clamp_pct "$five_pct")
  five_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$json")

  seven_pct=$(jq -r '.rate_limits.seven_day.used_percentage // 0' <<<"$json")
  seven_pct=${seven_pct%.*}
  seven_pct=$(clamp_pct "$seven_pct")
  seven_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$json")

  five_color=$(color_for "$five_pct")
  seven_color=$(color_for "$seven_pct")

  five_label="5h Limit ${five_color}${five_pct}%${RESET}"
  [[ -n "$five_reset" ]] && five_label+="${DIM} (${RESET}$(fmt_reset "$five_reset")${DIM})${RESET}"

  seven_label="7d Limit ${seven_color}${seven_pct}%${RESET}"
  [[ -n "$seven_reset" ]] && seven_label+="${DIM} (${RESET}$(fmt_reset "$seven_reset")${DIM})${RESET}"

  segments+=("$five_label")
  segments+=("$seven_label")
else
  # API-key billing: no rate_limits, show session cost instead
  cost=$(jq -r '.cost.total_cost_usd // empty' <<<"$json")
  if [[ -n "$cost" ]]; then
    segments+=("\$$(printf '%.2f' "$cost") session")
  fi
fi

# join with " │ "
out=""
for i in "${!segments[@]}"; do
  if [[ $i -eq 0 ]]; then
    out="${segments[$i]}"
  else
    out="${out} │ ${segments[$i]}"
  fi
done
printf '%s\n' "$out"
