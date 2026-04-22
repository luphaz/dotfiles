#!/usr/bin/env bash
# <xbar.title>tmux Session Switcher</xbar.title>
# <xbar.desc>List tmux sessions — click to jump, spawns Ghostty+tmux if cold</xbar.desc>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.dependencies>tmux,ghostty</xbar.dependencies>

export PATH="/opt/homebrew/bin:$PATH"

TMUX_JUMP="$HOME/.dotfiles/shell/bin/tmux-jump"

# ── Display mode ─────────────────────────────────────────────────────
if ! tmux list-sessions &>/dev/null 2>&1; then
  echo "🖥️ tmux · off | color=gray"
  echo "---"
  echo "No tmux server"
  exit 0
fi

# Most recently active attached session = "current"
CURRENT=$(tmux list-sessions -F '#{session_activity} #{session_attached} #{session_name}' 2>/dev/null \
  | sort -rn | awk '$2=="1" {print $3; exit}')
COUNT=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')

echo "🖥️ tmux ${CURRENT:-—}·${COUNT}"
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

      # Delegate click to tmux-jump — handles both the warm (switch-client)
      # and cold (spawn Ghostty+tmux attach) cases uniformly.
      echo "$label | bash=$TMUX_JUMP param1=$name terminal=false refresh=true $opts"

      # Detail line: current command + last non-blank pane line
      cmd=$(tmux display-message -t "$name" -p '#{pane_current_command}' 2>/dev/null)
      last=$(tmux capture-pane -t "$name" -p -J 2>/dev/null \
        | grep -v '^[[:space:]]*$' | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-60)

      detail=""
      [ -n "$cmd"  ] && detail="⚙ $cmd"
      [ -n "$last" ] && detail="$detail  ·  $last"
      [ -n "$detail" ] && echo "$detail | size=12 color=#8b949e"
      echo "---"
    done

echo "Refresh | refresh=true"
