#!/usr/bin/env bash
# <xbar.title>Slack Unreads</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Shows unread Slack message counts. Uses macOS lsappinfo for total count (no token needed). With a Slack user token, shows per-channel breakdown.</xbar.desc>
# <xbar.dependencies>jq</xbar.dependencies>

# --- Configuration ---
# For per-channel breakdown, store a Slack User OAuth Token (xoxp-...) in macOS Keychain:
#   security add-generic-password -a "$USER" -s "xbar-slack-token" -w "xoxp-your-token-here"
#
# To create a token:
#   1. Go to https://api.slack.com/apps and create a new app
#   2. Under "OAuth & Permissions", add scopes: channels:read, groups:read, im:read, mpim:read
#   3. Install to your workspace, copy the User OAuth Token (xoxp-...)
#   4. Store it in Keychain with the command above
#
# Without a token, the plugin still shows total unread count via Slack.app's dock badge.

JQ=/opt/homebrew/bin/jq
CURL=/usr/bin/curl

# --- Retrieve Slack token (optional) ---
SLACK_TOKEN="${SLACK_TOKEN:-}"
if [ -z "$SLACK_TOKEN" ]; then
  SLACK_TOKEN=$(security find-generic-password -a "$USER" -s "xbar-slack-token" -w 2>/dev/null)
fi

# --- Helper: get total unread count from Slack.app dock badge via lsappinfo ---
get_badge_count() {
  local raw label
  raw=$(lsappinfo info -only StatusLabel "Slack" 2>/dev/null)
  # Format: "StatusLabel"={ "label"="10" } or "StatusLabel"=(null)
  label=$(echo "$raw" | sed -n 's/.*"label"="\([^"]*\)".*/\1/p')
  if [ -n "$label" ] && [ "$label" != "(null)" ]; then
    echo "$label"
  else
    echo "0"
  fi
}

# --- Check if Slack.app is running ---
if ! pgrep -xq "Slack"; then
  echo "S:- | color=#8b949e"
  echo "---"
  echo "Slack is not running"
  echo "Open Slack | bash=/usr/bin/open param1=-a param2=Slack terminal=false"
  exit 0
fi

# --- Mode 1: API mode (per-channel breakdown) ---
if [ -n "$SLACK_TOKEN" ]; then
  # Fetch conversations list with unread counts
  JSON=$($CURL -sfL --max-time 10 \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    "https://slack.com/api/conversations.list?types=public_channel,private_channel,mpim,im&exclude_archived=true&limit=200" 2>/dev/null)

  if [ -z "$JSON" ] || [ "$(echo "$JSON" | $JQ -r '.ok')" != "true" ]; then
    # API failed, fall back to badge count
    BADGE=$(get_badge_count)
    if [ "$BADGE" -gt 0 ] 2>/dev/null; then
      echo "S:${BADGE} | color=#f97583"
    else
      echo "S:0 | color=#8b949e"
    fi
    echo "---"
    ERR=$(echo "$JSON" | $JQ -r '.error // "unknown"' 2>/dev/null)
    echo "API error: $ERR | color=#f97583"
    echo "Token may be invalid or expired"
    echo "---"
    echo "Falling back to dock badge count: $BADGE"
    exit 0
  fi

  # Extract channels with unreads (bash 3.2 compatible -- no associative arrays)
  # Produce lines: unread_count\tname
  UNREADS=$( echo "$JSON" | $JQ -r '
    .channels[]
    | select(.is_archived == false)
    | select(.unread_count_display > 0)
    | "\(.unread_count_display)\t\(
        if .is_im == true then
          "DM: \(.user // "unknown")"
        elif .name then
          "#\(.name)"
        else
          "(unnamed)"
        end
      )"
  ' 2>/dev/null )

  TOTAL=0
  CHANNEL_COUNT=0
  # Read lines into indexed arrays (bash 3.2 safe)
  COUNTS=()
  NAMES=()
  while IFS=$'\t' read -r cnt nm; do
    if [ -n "$cnt" ] && [ "$cnt" -gt 0 ] 2>/dev/null; then
      TOTAL=$((TOTAL + cnt))
      CHANNEL_COUNT=$((CHANNEL_COUNT + 1))
      COUNTS[${#COUNTS[@]}]="$cnt"
      NAMES[${#NAMES[@]}]="$nm"
    fi
  done <<< "$UNREADS"

  # Menu bar
  if [ "$TOTAL" -gt 0 ]; then
    echo "S:${TOTAL} | color=#f97583"
  else
    echo "S:0 | color=#8b949e"
  fi

  echo "---"

  if [ "$CHANNEL_COUNT" -gt 0 ]; then
    echo "${CHANNEL_COUNT} channels with unreads | color=#8b949e size=12"
    echo "---"
    # Sort by count descending (use a temp file for bash 3.2 compat)
    TMPFILE=$(mktemp)
    i=0
    while [ "$i" -lt "${#COUNTS[@]}" ]; do
      printf '%s\t%s\n' "${COUNTS[$i]}" "${NAMES[$i]}" >> "$TMPFILE"
      i=$((i + 1))
    done
    sort -t$'\t' -k1 -rn "$TMPFILE" | while IFS=$'\t' read -r cnt nm; do
      echo "${nm}  (${cnt}) | color=#c9d1d9"
    done
    rm -f "$TMPFILE"
  else
    echo "No unread messages | color=#8b949e"
  fi

  echo "---"
  echo "Open Slack | bash=/usr/bin/open param1=-a param2=Slack terminal=false"
  exit 0
fi

# --- Mode 2: Badge mode (no token, uses lsappinfo) ---
BADGE=$(get_badge_count)

if [ "$BADGE" -gt 0 ] 2>/dev/null; then
  echo "S:${BADGE} | color=#f97583"
else
  echo "S:0 | color=#8b949e"
fi

echo "---"

if [ "$BADGE" -gt 0 ] 2>/dev/null; then
  echo "${BADGE} unread messages | color=#c9d1d9"
else
  echo "No unread messages | color=#8b949e"
fi

echo "---"
echo "Open Slack | bash=/usr/bin/open param1=-a param2=Slack terminal=false"
echo "---"
echo "Per-channel details need a Slack token | color=#8b949e size=11"
echo "Add token to Keychain: | color=#8b949e size=11"
echo "  security add-generic-password -a \"\$USER\" -s \"xbar-slack-token\" -w \"xoxp-...\" | color=#8b949e size=11"
