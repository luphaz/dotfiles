#!/usr/bin/env bash
# <xbar.title>Claude Code Sessions</xbar.title>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Active Claude Code sessions — click to jump to the tmux pane in Ghostty</xbar.desc>
# <xbar.dependencies>jq,tmux,ghostty</xbar.dependencies>

source "$HOME/.dotfiles/xbar/plugin-guard.sh"

export PATH="/opt/homebrew/bin:$PATH"
JQ=/opt/homebrew/bin/jq
SESSIONS_DIR="$HOME/.claude/sessions"
PROJECTS_DIR="$HOME/.claude/projects"
TMUX_JUMP="$HOME/.dotfiles/shell/bin/tmux-jump"
SCRIPT="${BASH_SOURCE[0]}"

# ── Click handler ────────────────────────────────────────────────────
# Resolve session:window.pane for <pid> at click time (tmux state may have
# shifted since the dropdown was rendered) and hand off to tmux-jump. If we
# can't find a tmux ancestor, at least bring Ghostty forward so the user can
# navigate manually.
if [ "$1" = "jump" ] && [ -n "$2" ]; then
  pid="$2"
  target=""
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    target=$(tmux list-panes -a -F '#{pane_pid} #{session_name}:#{window_index}.#{pane_index}' 2>/dev/null \
      | awk -v p="$pid" '$1==p {print $2; exit}')
    [ -n "$target" ] && break
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  if [ -n "$target" ]; then
    exec "$TMUX_JUMP" "$target"
  else
    open -a Ghostty
  fi
  exit 0
fi

# ── Display ──────────────────────────────────────────────────────────
if [ ! -d "$SESSIONS_DIR" ]; then
  echo "🤖 claude 0 | color=#586069"
  exit 0
fi

ACTIVE=()
for f in "$SESSIONS_DIR"/*.json; do
  [ -f "$f" ] || continue
  pid=$($JQ -r '.pid' "$f" 2>/dev/null)
  if kill -0 "$pid" 2>/dev/null; then
    ACTIVE+=("$f")
  fi
done

COUNT=${#ACTIVE[@]}
if [ "$COUNT" -eq 0 ]; then
  echo "🤖 claude 0 | color=#586069"
  echo "---"
  echo "No active Claude sessions"
  exit 0
fi

# Pre-scan to pick the aggregate color for the menu-bar title: any session
# actively burning CPU → green, else any waiting-for-input (process sleeping) →
# amber, else → grey.
ANY_WORKING=false
ANY_WAITING=false
for f in "${ACTIVE[@]}"; do
  pid=$($JQ -r '.pid' "$f" 2>/dev/null)
  cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ')
  cpu_int=$(printf "%.0f" "${cpu:-0}")
  proc_state=$(ps -p "$pid" -o state= 2>/dev/null | tr -d ' ')
  if [ "$cpu_int" -gt 5 ]; then
    ANY_WORKING=true
  elif [ "${proc_state:0:1}" = "S" ]; then
    ANY_WAITING=true
  fi
done

if $ANY_WORKING; then
  echo "🤖 claude ${COUNT} | color=#3fb950"
elif $ANY_WAITING; then
  echo "🤖 claude ${COUNT} | color=#ffab70"
else
  echo "🤖 claude ${COUNT} | color=#8b949e"
fi

echo "---"

for f in "${ACTIVE[@]}"; do
  session=$($JQ -c '.' "$f" 2>/dev/null)
  pid=$(echo "$session" | $JQ -r '.pid')
  cwd=$(echo "$session" | $JQ -r '.cwd')
  session_id=$(echo "$session" | $JQ -r '.sessionId')
  started_at=$(echo "$session" | $JQ -r '.startedAt')

  # `${cwd/#$HOME/~}` silently no-ops on bash 5.3 (the one shipping via
  # Linuxbrew/Homebrew today), so do the prefix strip + ~ prepend manually.
  if [[ "$cwd" == "$HOME"* ]]; then
    short_cwd="~${cwd##"$HOME"}"
  else
    short_cwd="$cwd"
  fi
  dir_name=$(basename "$cwd")

  now_ms=$(($(date +%s) * 1000))
  age_s=$(( (now_ms - started_at) / 1000 ))
  if [ "$age_s" -lt 3600 ]; then
    age="$((age_s / 60))m"
  else
    age="$((age_s / 3600))h$((age_s % 3600 / 60))m"
  fi

  cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ')
  proc_state=$(ps -p "$pid" -o state= 2>/dev/null | tr -d ' ')
  cpu_int=$(printf "%.0f" "${cpu:-0}")
  if [ "$cpu_int" -gt 5 ]; then
    status="working"
    status_color="#3fb950"
  elif [ "${proc_state:0:1}" = "S" ]; then
    status="waiting for input"
    status_color="#ffab70"
  else
    status="idle"
    status_color="#8b949e"
  fi

  # Topic: first user message, with boilerplate lines (<…> tags, paths, etc.)
  # filtered out. Best-effort; silent if the conversation log is missing.
  topic=""
  project_key=$(echo "$cwd" | sed 's|[/.]|-|g')
  conv_file="$PROJECTS_DIR/$project_key/$session_id.jsonl"
  if [ -f "$conv_file" ]; then
    topic=$(head -50 "$conv_file" | $JQ -r '
      select(.type == "user") | .message |
      if type == "string" then .
      elif type == "object" and .content then
        (.content | if type == "array" then map(select(.type == "text") | .text) | first
        elif type == "string" then . else empty end)
      else empty end' 2>/dev/null | grep -vE '<|^Base directory|^/' | head -1 | cut -c1-60)
  fi

  # Click handler always fires: the script re-resolves the pane at click time.
  click="bash=$SCRIPT param1=jump param2=$pid terminal=false refresh=false"

  short_topic=$(echo "$topic" | cut -c1-60)
  [ "${#topic}" -gt 60 ] && short_topic="${short_topic}…"

  echo "$dir_name  ·  $status  ·  ${age} | color=$status_color $click"
  [ -n "$short_topic" ] && echo "$short_topic | size=12 color=#586069"
  echo "$short_cwd | size=11 color=#8b949e"
  echo "---"
done

echo "Refresh | refresh=true"
