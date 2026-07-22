#!/bin/bash
# Claude Code statusline
# Segments: session name | model (effort) | context usage | plan usage | git branch/status

input=$(cat)

session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
if [ -z "$session_name" ]; then
  session_name="${session_id: -8}"
fi

model=$(echo "$input" | jq -r '.model.display_name // "?"')
effort=$(echo "$input" | jq -r '.effort.level // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# Colors (kept subdued since the statusline renders dimmed in-terminal)
RESET=$'\033[0m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RED=$'\033[31m'
BLUE=$'\033[34m'
DIM=$'\033[2m'

# --- Session ---
seg_session="${CYAN}${session_name}${RESET}"

# --- Model + effort ---
if [ -n "$effort" ]; then
  seg_model="${MAGENTA}${model} (${effort})${RESET}"
else
  seg_model="${MAGENTA}${model}${RESET}"
fi

# --- Context usage ---
seg_context=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf '%.0f' "$used_pct")
  if [ "$ctx_int" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$ctx_int" -ge 50 ]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  seg_context="${ctx_color}ctx:${ctx_int}%${RESET}"
fi

# --- Plan (rate limit) usage ---
seg_plan=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  parts=""
  if [ -n "$five_pct" ]; then
    parts="5h:$(printf '%.0f' "$five_pct")%"
  fi
  if [ -n "$week_pct" ]; then
    [ -n "$parts" ] && parts="$parts "
    parts="${parts}7d:$(printf '%.0f' "$week_pct")%"
  fi
  seg_plan="${BLUE}${parts}${RESET}"
fi

# --- Git branch + status ---
seg_git=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
  if [ -n "$branch" ]; then
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
      seg_git="${GREEN}${branch}${RESET}${RED}*${RESET}"
    else
      seg_git="${GREEN}${branch}${RESET}"
    fi
  fi
fi

# --- Assemble ---
out="$seg_session"
out="$out ${DIM}|${RESET} $seg_model"
[ -n "$seg_context" ] && out="$out ${DIM}|${RESET} $seg_context"
[ -n "$seg_plan" ] && out="$out ${DIM}|${RESET} $seg_plan"
[ -n "$seg_git" ] && out="$out ${DIM}|${RESET} $seg_git"

printf '%s' "$out"
