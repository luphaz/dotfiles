#!/usr/bin/env bash
# <xbar.title>Services Status</xbar.title>
# <xbar.version>v1.1</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Shows status of key services: GitHub, Anthropic, OpenAI, AWS, Slack, Zoom</xbar.desc>
# <xbar.dependencies>curl,jq</xbar.dependencies>

source "$HOME/.dotfiles/xbar/plugin-guard.sh"

JQ=/opt/homebrew/bin/jq
TMPDIR=$(mktemp -d)

# Fetch Statuspage services in parallel
fetch_statuspage() {
  local name="$1" url="$2"
  json=$(curl -sfL --max-time 5 "$url" 2>/dev/null)
  if [ -n "$json" ]; then
    echo "$json" | $JQ -r '.status.indicator // "unknown"' > "$TMPDIR/${name}.status"
    echo "$json" | $JQ -r '.status.description // "Unknown"' > "$TMPDIR/${name}.desc"
  else
    echo "fetch_error" > "$TMPDIR/${name}.status"
    echo "Unreachable" > "$TMPDIR/${name}.desc"
  fi
}

fetch_statuspage GitHub   "https://www.githubstatus.com/api/v2/status.json" &
fetch_statuspage Anthropic "https://status.anthropic.com/api/v2/status.json" &
fetch_statuspage OpenAI   "https://status.openai.com/api/v2/status.json" &
fetch_statuspage Zoom     "https://status.zoom.us/api/v2/status.json" &

# Slack (different API format)
(
  json=$(curl -sfL --max-time 5 "https://status.slack.com/api/v2.0.0/current" 2>/dev/null)
  if [ -n "$json" ]; then
    slack_status=$(echo "$json" | $JQ -r '.status' 2>/dev/null)
    incidents=$(echo "$json" | $JQ -r '.active_incidents | length' 2>/dev/null)
    if [ "$slack_status" = "ok" ] && [ "${incidents:-0}" = "0" ]; then
      echo "none" > "$TMPDIR/Slack.status"
      echo "All Systems Operational" > "$TMPDIR/Slack.desc"
    else
      echo "major" > "$TMPDIR/Slack.status"
      echo "Active incidents: ${incidents}" > "$TMPDIR/Slack.desc"
    fi
  else
    echo "fetch_error" > "$TMPDIR/Slack.status"
    echo "Unreachable" > "$TMPDIR/Slack.desc"
  fi
) &

# AWS (no public status API — HTTP health check)
(
  http_code=$(curl -sfL -o /dev/null -w "%{http_code}" --max-time 5 "https://health.aws.amazon.com/health/status" 2>/dev/null)
  if [ "$http_code" = "200" ]; then
    echo "none" > "$TMPDIR/AWS.status"
    echo "Reachable" > "$TMPDIR/AWS.desc"
  else
    echo "fetch_error" > "$TMPDIR/AWS.status"
    echo "HTTP $http_code" > "$TMPDIR/AWS.desc"
  fi
) &

wait

# Tally non-OK services so the menu-bar title tells you at a glance whether
# something needs attention without opening the dropdown.
DOWN_COUNT=0
HAS_MAJOR=false
for name in GitHub Anthropic OpenAI AWS Slack Zoom; do
  s=$(cat "$TMPDIR/${name}.status" 2>/dev/null)
  if [ "$s" != "none" ]; then
    DOWN_COUNT=$((DOWN_COUNT + 1))
    [ "$s" = "major" ] && HAS_MAJOR=true
  fi
done

if [ "$DOWN_COUNT" -eq 0 ]; then
  echo "🚦 services ok | color=#3fb950"
elif $HAS_MAJOR; then
  echo "🚦 services ${DOWN_COUNT}↓ | color=#f97583"
else
  echo "🚦 services ${DOWN_COUNT}↓ | color=#ffab70"
fi

echo "---"

# Display each service
print_service() {
  local name="$1" href="$2"
  local s desc icon color
  s=$(cat "$TMPDIR/${name}.status" 2>/dev/null)
  desc=$(cat "$TMPDIR/${name}.desc" 2>/dev/null)

  case "$s" in
    none)        icon="✓"; color="#3fb950" ;;
    minor)       icon="●"; color="#ffab70" ;;
    major)       icon="✗"; color="#f97583" ;;
    maintenance) icon="▪"; color="#8b949e" ;;
    fetch_error) icon="?"; color="#8b949e" ;;
    *)           icon="?"; color="#8b949e" ;;
  esac

  echo "$icon $name: $desc | color=$color href=$href"
}

print_service GitHub    "https://www.githubstatus.com"
print_service Anthropic "https://status.claude.com"
print_service OpenAI    "https://status.openai.com"
print_service AWS       "https://health.aws.amazon.com/health/status"
print_service Slack     "https://status.slack.com"
print_service Zoom      "https://www.zoomstatus.com"

rm -rf "$TMPDIR"
