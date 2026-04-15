#!/usr/bin/env bash
# <xbar.title>tmux Session Switcher</xbar.title>
# <xbar.desc>List tmux sessions — click to switch and focus Ghostty</xbar.desc>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.dependencies>tmux</xbar.dependencies>

export PATH="/opt/homebrew/bin:$PATH"

SCRIPT="${BASH_SOURCE[0]}"

# ── Switch mode (triggered by menu click) ────────────────────────────
if [ -n "$1" ]; then
  # Switch the most recently active tmux client to the target session
  CLIENT=$(tmux list-clients -F '#{client_activity} #{client_name}' 2>/dev/null \
    | sort -rn | head -1 | awk '{print $2}')
  [ -n "$CLIENT" ] && tmux switch-client -c "$CLIENT" -t "$1" 2>/dev/null
  open -a Ghostty
  exit 0
fi

# ── Display mode ─────────────────────────────────────────────────────
if ! tmux list-sessions &>/dev/null 2>&1; then
  echo "tmux | color=gray"
  echo "---"
  echo "No tmux server"
  exit 0
fi

# Most recently active attached session = "current"
CURRENT=$(tmux list-sessions -F '#{session_activity} #{session_attached} #{session_name}' 2>/dev/null \
  | sort -rn | awk '$2=="1" {print $3; exit}')
COUNT=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')

echo "[${CURRENT:-tmux}:${COUNT}]"
echo "---"

tmux list-sessions -F '#{session_activity} #{session_name} #{session_windows} #{session_attached}' 2>/dev/null \
  | sort -rn \
  | while IFS= read -r line; do
      name=$(echo "$line"    | awk '{print $2}')
      windows=$(echo "$line" | awk '{print $3}')
      attached=$(echo "$line"| awk '{print $4}')

      if [ "$name" = "$CURRENT" ]; then
        label="● $name  ($windows windows)"
        opts="color=#ff6b6b font=Menlo-Bold size=13"
      elif [ "$attached" = "1" ]; then
        label="○ $name  ($windows windows)"
        opts="color=#98c379"
      else
        label="  $name  ($windows windows)"
        opts=""
      fi

      echo "$label | bash=$SCRIPT param1=$name terminal=false refresh=true $opts"

      # Detail line: current command + last output line
      cmd=$(tmux display-message -t "$name" -p '#{pane_current_command}' 2>/dev/null)
      last=$(tmux capture-pane -t "$name" -p -J 2>/dev/null \
        | grep -v '^[[:space:]]*$' | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-60)

      detail=""
      [ -n "$cmd"  ] && detail="⚙ $cmd"
      [ -n "$last" ] && detail="$detail  ·  $last"
      [ -n "$detail" ] && echo "$detail | size=12 color=#8b949e"
      echo "---"
    done

echo "---"
echo "Refresh | refresh=true"
