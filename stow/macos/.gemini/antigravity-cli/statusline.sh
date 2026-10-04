#!/bin/bash
set -euo pipefail

# Based on Google's official Antigravity CLI statusline example.
# Quota is read from the JSON payload supplied by agy on stdin. This script
# deliberately does not spawn quota workers, inspect processes, or call lsof.

R=$'\033[0m'
B=$'\033[1m'
D=$'\033[2m'
I=$'\033[3m'
FG_GRAY=$'\033[90m'
FG_BRIGHT_RED=$'\033[91m'
FG_BRIGHT_GREEN=$'\033[92m'
FG_BRIGHT_YELLOW=$'\033[93m'
FG_BRIGHT_BLUE=$'\033[94m'
FG_BRIGHT_MAGENTA=$'\033[95m'
FG_BRIGHT_CYAN=$'\033[96m'
FG_BRIGHT_WHITE=$'\033[97m'
NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'statusline unavailable: jq is not installed'
  exit 0
fi

# Parse every displayed value in one jq process. The quota object is part of
# agy's documented statusLine payload; bucket names vary by account/model.
if ! PARSED_PAYLOAD=$(jq -r '
    def number_or($fallback):
      if type == "number" then
        if isfinite then . else $fallback end
      elif type == "string" then
        (tonumber? // $fallback) as $number
        | if ($number | type) == "number" and ($number | isfinite)
          then $number
          else $fallback
          end
      else $fallback
      end;
    def clamp($minimum; $maximum):
      if . < $minimum then $minimum
      elif . > $maximum then $maximum
      else .
      end;
    def countdown:
      if . == null then ""
      elif . >= 86400 then "\((. / 86400) | floor)d \(((. % 86400) / 3600) | floor)h"
      elif . >= 3600 then "\((. / 3600) | floor)h \(((. % 3600) / 60) | floor)m"
      elif . >= 60 then "\((. / 60) | floor)m"
      else "\(. | floor)s"
      end;
    def bucket_text:
      . as $bucket
      | if ($bucket | type) != "object" then null
        else (($bucket.remaining_fraction // null) | number_or(null) | clamp(0; 1)) as $fraction
        | (($bucket.reset_in_seconds // null) | number_or(null)
           | if . == null then null elif . < 0 then 0 else floor end) as $reset
        | if $fraction == null then null
          else
            (($fraction * 100) | round) as $percent
            | "\($percent)%"
              + (if $reset != null
                 then " ↻ " + ($reset | countdown)
                 else ""
                 end)
          end
        end;
    (
      (.agent_state // "idle"),
      ((.context_window.used_percentage // 0) | number_or(0) | clamp(0; 100)),
      ((.context_window.used_percentage // 0) | number_or(0) | clamp(0; 100) | floor),
      (.vcs.branch // ""),
      (.vcs.dirty // false),
      (.sandbox.enabled // false),
      (.artifact_count // 0),
      (if .subagents | type == "array" then (.subagents | length) else 0 end),
      (.task_count // 0),
      (.model.display_name // ""),
      ((.terminal_width // 80) | number_or(80) | clamp(1; 1000) | floor)
    ),
    (
      [
        ((if (.quota | type) == "object" then .quota else {} end) | to_entries[]?
         | .key as $key
         | (.value | bucket_text) as $text
         | select($text != null)
         | "\($key) \($text)")
      ] | if length == 0 then "-" else join(" · ") end
    ),
    (
      ((.context_window.used_percentage // 0) | number_or(0) | clamp(0; 100)) as $used_pct
      | if $used_pct >= 90 then "high"
        elif $used_pct >= 60 then "medium"
        else "low"
        end
    )
  ' 2>/dev/null); then
  printf '%s\n' 'statusline unavailable: invalid agy payload' >&2
  exit 0
fi

{
  read -r STATE
  read -r USED_PCT
  read -r PCT_INT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r SANDBOX
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL
  read -r COLS
  read -r QUOTA
  read -r PCT_TIER
} <<< "$PARSED_PAYLOAD"

STATE_UPPER=${STATE^^}
case "$STATE" in
  idle) S="${FG_BRIGHT_GREEN}${B}● READY${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}◆ THINKING${R}" ;;
  working) S="${FG_BRIGHT_CYAN}${B}⚙ WORKING${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}🔧 TOOL${R}" ;;
  *) S="${FG_BRIGHT_WHITE}${B}⏳ ${STATE_UPPER}${R}" ;;
esac

M=""
if [ -n "$MODEL" ]; then
  M="${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${I}${MODEL}${R}"
fi

V=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    V="${FG_GRAY} ╱ ${FG_BRIGHT_RED}${VCS_BRANCH}${FG_BRIGHT_YELLOW}*${R}"
  else
    V="${FG_GRAY} ╱ ${FG_BRIGHT_BLUE}${VCS_BRANCH}${R}"
  fi
fi

if [ "$SANDBOX" = "true" ]; then
  SB="${FG_GRAY}sandbox ${FG_BRIGHT_GREEN}${B}ON${R}"
else
  SB="${FG_GRAY}sandbox off${R}"
fi

PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
BAR_LEN=15
FILLED=$((PCT_INT * BAR_LEN / 100))
REMAINDER=$(( (PCT_INT * BAR_LEN) % 100 ))
case "$PCT_TIER" in
  high) BAR_COLOR="$FG_BRIGHT_RED" ;;
  medium) BAR_COLOR="$FG_BRIGHT_YELLOW" ;;
  *) BAR_COLOR="$FG_BRIGHT_WHITE" ;;
esac
BAR=""
for ((i = 0; i < BAR_LEN; i++)); do
  if [ "$i" -lt "$FILLED" ]; then
    BAR="${BAR}█"
  elif [ "$i" -eq "$FILLED" ]; then
    if [ "$REMAINDER" -ge 75 ]; then BAR="${BAR}▓"
    elif [ "$REMAINDER" -ge 50 ]; then BAR="${BAR}▒"
    elif [ "$REMAINDER" -ge 25 ]; then BAR="${BAR}░"
    else BAR="${BAR}·"
    fi
  else
    BAR="${BAR}·"
  fi
done

CTX="${FG_GRAY}ctx ${BAR_COLOR}${BAR} ${NUM_COLOR}${PCT_FMT}%${R}"
ART_FMT="${FG_GRAY}artifacts ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_FMT="${FG_GRAY}subagents ${NUM_COLOR}${SUBAGENTS}${R}"
BG_FMT="${FG_GRAY}tasks ${NUM_COLOR}${BG_TASKS}${R}"
QUOTA_LINES=()
if [ -n "$QUOTA" ] && [ "$QUOTA" != "-" ]; then
  remaining_quota="$QUOTA"
  current_quota=""
  max_quota_text=$((COLS - 6))
  if [ "$max_quota_text" -lt 1 ]; then max_quota_text=1; fi
  while :; do
    if [[ "$remaining_quota" == *" · "* ]]; then
      quota_part="${remaining_quota%% · *}"
      remaining_quota="${remaining_quota#* · }"
    else
      quota_part="$remaining_quota"
      remaining_quota=""
    fi

    if [ -z "$current_quota" ]; then
      current_quota="$quota_part"
    elif [ $(( ${#current_quota} + 3 + ${#quota_part} )) -le "$max_quota_text" ]; then
      current_quota="${current_quota} · ${quota_part}"
    else
      QUOTA_LINES+=("$current_quota")
      current_quota="$quota_part"
    fi

    [ -z "$remaining_quota" ] && break
  done
  [ -n "$current_quota" ] && QUOTA_LINES+=("$current_quota")
fi
DOT="${FG_GRAY} · ${R}"

print_quota_lines() {
  local quota_line
  for quota_line in "${QUOTA_LINES[@]}"; do
    printf '%s\n' "${FG_GRAY}quota ${NUM_COLOR}${quota_line}${R}"
  done
}

LINE1="${S}${M}${V}"
LINE2="${CTX}${DOT}${ART_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}${DOT}${SB}"

if [ "$COLS" -ge 120 ]; then
  printf '%s\n' "${LINE1}${FG_GRAY}  │  ${R}${LINE2}"
  print_quota_lines
elif [ "$COLS" -ge 80 ]; then
  printf '%s\n' "${FG_GRAY}╭─${R} ${LINE1}"
  printf '%s\n' "${FG_GRAY}╰─${R}${LINE2}"
  print_quota_lines
else
  printf '%s\n' "${S}${M}"
  printf '%s\n' "${CTX}${DOT}${BG_FMT}"
  print_quota_lines
fi
