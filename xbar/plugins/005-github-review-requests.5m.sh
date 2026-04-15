#!/usr/bin/env bash
# <xbar.title>Github review requests</xbar.title>
# <xbar.desc>Shows a list of PRs that need to be reviewed</xbar.desc>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.dependencies>gh,jq</xbar.dependencies>

export PATH="/opt/homebrew/bin:$HOME/dd/devtools/bin:$PATH"

GH="$HOME/dd/devtools/bin/gh"
JQ=/opt/homebrew/bin/jq

JSON=$($GH search prs --review-requested=@me --state=open \
  --json repository,title,number,url,author,createdAt,labels \
  --limit 100 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$JSON" ]; then
  echo "⚠ PRs | color=red"
  echo "---"
  echo "Failed to fetch PRs via gh"
  exit 0
fi

# Filter to team members only
TEAM_AUTHORS='["AxelleFesard", "oceane-vlt", "LorisFriedel", "dexter0195", "d33d33", "stombre"]'
JSON=$(echo "$JSON" | $JQ --argjson team "$TEAM_AUTHORS" '[.[] | select([.author.login] | inside($team))]')

COUNT=$(echo "$JSON" | $JQ 'length')

# Resolve unique author logins to display names via a single GraphQL query
LOGINS=$(echo "$JSON" | $JQ -r '[.[].author.login] | unique | .[]')
GQL_QUERY="{"
i=0
for login in $LOGINS; do
  # GraphQL aliases must be alphanumeric — replace hyphens/dots/brackets
  alias=$(echo "$login" | sed 's/[^a-zA-Z0-9]/_/g')
  GQL_QUERY="${GQL_QUERY} u${alias}: user(login: \"${login}\") { login name }"
  i=$((i + 1))
done
GQL_QUERY="${GQL_QUERY} }"

NAME_MAP=$($GH api graphql -f query="$GQL_QUERY" 2>/dev/null \
  | $JQ '[.data | to_entries[].value | select(. != null) |
    {(.login): (if .name and .name != "" then "\(.name) (\(.login))" else .login end)}
  ] | add // {}')

STALE_DAYS=3
STALE_COUNT=$(echo "$JSON" | $JQ --arg days "$STALE_DAYS" '
  (now - ($days | tonumber) * 86400) as $cutoff |
  [.[] | select((.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < $cutoff)] | length')

if [ "$STALE_COUNT" -gt 0 ]; then
  echo "#${COUNT} (${STALE_COUNT} stale) | color=#f97583"
else
  echo "#${COUNT}"
fi
echo "---"

echo "$JSON" | $JQ -r --argjson names "$NAME_MAP" --arg days "$STALE_DAYS" '
  (now - ($days | tonumber) * 86400) as $cutoff |
  def repo_key:
    if .repository.name == "terraform-config" then "0"
    elif .repository.name == "cloud-inventory" then "1"
    else "2-\(.repository.name)"
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
