#!/usr/bin/env bash
# <xbar.title>Homebrew Updates</xbar.title>
# <xbar.author>killercup</xbar.author>
# <xbar.author.github>killercup</xbar.author.github>
# <xbar.desc>List available updates from Homebrew (OS X)</xbar.desc>

source "$HOME/.dotfiles/xbar/plugin-guard.sh"

exit_with_error() {
  echo "🍺 err | color=red";
  exit 1;
}

/opt/homebrew/bin/brew update > /dev/null 2>&1 || exit_with_error;

PINNED=$(/opt/homebrew/bin/brew list --pinned);
OUTDATED=$(/opt/homebrew/bin/brew outdated --quiet);

# Sort both before comm — `brew outdated --quiet` output isn't collation-
# sorted, and BSD comm (macOS) prints "file N is not in sorted order" on
# stderr when it isn't. xbar treats any stderr output as plugin failure and
# stops rendering all subsequent plugins, which manifests as an empty menu.
UPDATES=$(comm -13 <(printf '%s\n' "$PINNED" | sort) <(printf '%s\n' "$OUTDATED" | sort))

UPDATE_COUNT=$(echo "$UPDATES" | grep -c '[^[:space:]]');

echo "🍺 brew $UPDATE_COUNT | dropdown=false"
echo "---";
if [ -n "$UPDATES" ]; then
  echo "Upgrade all | bash=/opt/homebrew/bin/brew param1=upgrade terminal=false refresh=true"
  echo "$UPDATES" | awk '{print $0 " | terminal=false refresh=true bash=/opt/homebrew/bin/brew param1=upgrade param2=" $1}'
fi
