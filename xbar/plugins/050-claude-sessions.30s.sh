#!/usr/bin/env bash
# <xbar.title>Claude Code Sessions</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Shows active Claude Code CLI sessions</xbar.desc>
# <xbar.dependencies>jq</xbar.dependencies>

JQ=/opt/homebrew/bin/jq
SESSIONS_DIR="$HOME/.claude/sessions"
PROJECTS_DIR="$HOME/.claude/projects"

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "C:0"
  exit 0
fi

# Collect active sessions (PID still running)
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
  echo "C:0 | color=#586069"
  echo "---"
  echo "No active Claude sessions"
  exit 0
fi

# Pre-scan: check if any session is waiting for input
ANY_WAITING=false
ANY_WORKING=false
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
  echo "C:${COUNT} | color=#3fb950"
elif $ANY_WAITING; then
  echo "C:${COUNT} | color=#8b949e"
else
  echo "C:${COUNT} | color=#ffab70"
fi

echo "---"

for f in "${ACTIVE[@]}"; do
  session=$($JQ -c '.' "$f" 2>/dev/null)
  pid=$(echo "$session" | $JQ -r '.pid')
  cwd=$(echo "$session" | $JQ -r '.cwd')
  session_id=$(echo "$session" | $JQ -r '.sessionId')
  started_at=$(echo "$session" | $JQ -r '.startedAt')

  # Shorten cwd
  short_cwd="${cwd/#$HOME/~}"
  # Just the last dir component for the title
  dir_name=$(basename "$cwd")

  # Session age
  now_ms=$(($(date +%s) * 1000))
  age_s=$(( (now_ms - started_at) / 1000 ))
  if [ "$age_s" -lt 3600 ]; then
    age="$((age_s / 60))m"
  else
    age="$((age_s / 3600))h$((age_s % 3600 / 60))m"
  fi

  # CPU and process state
  cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ')
  proc_state=$(ps -p "$pid" -o state= 2>/dev/null | tr -d ' ')
  cpu_int=$(printf "%.0f" "${cpu:-0}")

  # Determine session state:
  #   CPU > 5%         → working (actively processing)
  #   Process sleeping  → waiting for input
  #   Low CPU but running → thinking/idle
  if [ "$cpu_int" -gt 5 ]; then
    status="working"
    status_color="#3fb950"
  elif [ "${proc_state:0:1}" = "S" ]; then
    status="waiting for input"
    status_color="#8b949e"
  else
    status="idle"
    status_color="#ffab70"
  fi

  # Find conversation file to extract topic
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

  # Display
  echo "$dir_name ($status) - ${age} | color=$status_color"
  if [ -n "$topic" ]; then
    echo "--$topic | size=12 color=#586069"
  fi
  echo "--$short_cwd | size=11 color=#586069"
  echo "--CPU: ${cpu}% - PID: $pid | size=11 color=#586069"
  echo "---"
done
