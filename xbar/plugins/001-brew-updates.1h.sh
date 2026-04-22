#!/usr/bin/env bash
# <xbar.title>Homebrew Updates</xbar.title>
# <xbar.author>killercup</xbar.author>
# <xbar.author.github>killercup</xbar.author.github>
# <xbar.desc>List available updates from Homebrew (OS X)</xbar.desc>

exit_with_error() {
  echo "🍺 err | color=red";
  exit 1;
}

/opt/homebrew/bin/brew update > /dev/null 2>&1 || exit_with_error;

PINNED=$(/opt/homebrew/bin/brew list --pinned);
OUTDATED=$(/opt/homebrew/bin/brew outdated --quiet);

UPDATES=$(comm -13 <(for X in "${PINNED[@]}"; do echo "${X}"; done) <(for X in "${OUTDATED[@]}"; do echo "${X}"; done))

UPDATE_COUNT=$(echo "$UPDATES" | grep -c '[^[:space:]]');

echo "🍺 brew $UPDATE_COUNT | dropdown=false"
echo "---";
if [ -n "$UPDATES" ]; then
  echo "Upgrade all | bash=/opt/homebrew/bin/brew param1=upgrade terminal=false refresh=true"
  echo "$UPDATES" | awk '{print $0 " | terminal=false refresh=true bash=/opt/homebrew/bin/brew param1=upgrade param2=" $1}'
fi
