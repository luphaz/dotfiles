#!/usr/bin/env bash
# <xbar.title>Github review requests</xbar.title>
# <xbar.desc>Shows a list of PRs that need to be reviewed</xbar.desc>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.dependencies>gh,jq</xbar.dependencies>

source "$HOME/.dotfiles/xbar/plugin-guard.sh"

export PATH="/opt/homebrew/bin:$HOME/dd/devtools/bin:$PATH"

GH="$HOME/.dd-dotfiles/bin/gh"
JQ=/opt/homebrew/bin/jq

# Load team authors and priority repos from dd-dotfiles (graceful fallback if missing)
TEAM_AUTHORS=$(cat "$HOME/.dd-dotfiles/git/authors" 2>/dev/null || echo '[]')
PRIORITY_REPOS=$(cat "$HOME/.dd-dotfiles/git/repositories" 2>/dev/null || echo '[]')

JSON=$($GH search prs --review-requested=@me --state=open \
  --json repository,title,number,url,author,createdAt,labels \
  --limit 100 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$JSON" ]; then
  echo "👀 err | color=red"
  echo "---"
  echo "Failed to fetch PRs via gh"
  exit 0
fi

# Filter to team members only
JSON=$(echo "$JSON" | $JQ --argjson team "$TEAM_AUTHORS" '[.[] | select([.author.login] | inside($team))]')

COUNT=$(echo "$JSON" | $JQ 'length')

if [ "$COUNT" -eq 0 ]; then
  echo "👀 review 0 | color=#24292f"
  echo "---"
  echo "Refresh | refresh=true"
  exit 0
fi

# Resolve unique author logins to display names via a single GraphQL query
LOGINS=$(echo "$JSON" | $JQ -r '[.[].author.login] | unique | .[]')

NAME_MAP='{}'
if [ -n "$LOGINS" ]; then
  GQL_QUERY="{"
  for login in $LOGINS; do
    alias=$(echo "$login" | sed 's/[^a-zA-Z0-9]/_/g')
    GQL_QUERY="${GQL_QUERY} u${alias}: user(login: \"${login}\") { login name }"
  done
  GQL_QUERY="${GQL_QUERY} }"

  NAME_MAP=$($GH api graphql -f query="$GQL_QUERY" 2>/dev/null \
    | $JQ '[.data | to_entries[].value | select(. != null) |
      {(.login): (if .name and .name != "" then "\(.name) (\(.login))" else .login end)}
    ] | add // {}' 2>/dev/null) || NAME_MAP='{}'
fi

STALE_DAYS=3
STALE_COUNT=$(echo "$JSON" | $JQ --arg days "$STALE_DAYS" '
  (now - ($days | tonumber) * 86400) as $cutoff |
  [.[] | select((.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < $cutoff)] | length')

if [ "$STALE_COUNT" -gt 0 ]; then
  echo "👀 review ${COUNT} (${STALE_COUNT} ⏰) | color=#f97583"
else
  echo "👀 review ${COUNT}"
fi
echo "---"

echo "$JSON" | $JQ -r --argjson names "$NAME_MAP" --arg days "$STALE_DAYS" --argjson priority_repos "$PRIORITY_REPOS" '
  (now - ($days | tonumber) * 86400) as $cutoff |
  def repo_key:
    .repository.name as $name |
    ($priority_repos | index($name)) as $idx |
    if $idx != null then "\($idx)"
    else "99-\($name)"
    end;
  def is_stale:
    (.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < $cutoff;
  def age_days:
    ((now - (.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime)) / 86400 | floor);
  sort_by(repo_key) | .[] |
  ($names[.author.login] // .author.login) as $author |
  (if is_stale then " color=#f97583" else "" end) as $stale_color |
  (if is_stale then " ⏰ \(age_days)d" else "" end) as $stale_tag |
  "\(.repository.nameWithOwner) - \(.title) | href=\(.url)\($stale_color)",
  "#\(.number) by \($author) - \(.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%B %d, %Y"))\($stale_tag) | size=12 color=#586069",
  "---"'

echo "Refresh | refresh=true"
