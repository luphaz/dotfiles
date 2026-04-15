#!/bin/bash
# <xbar.title>My Open PRs</xbar.title>
# <xbar.desc>Shows my open PRs with CI and review status</xbar.desc>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.dependencies>gh,jq</xbar.dependencies>

export PATH="/opt/homebrew/bin:$HOME/dd/devtools/bin:$PATH"

GH="$HOME/.dd-dotfiles/bin/gh"
JQ=/opt/homebrew/bin/jq

# --- Fetch open PRs authored by me ---
JSON=$($GH search prs --author=@me --state=open \
  --json repository,title,number,url,createdAt \
  --limit 100 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$JSON" ]; then
  echo "⚠ MY | color=red"
  echo "---"
  echo "Failed to fetch PRs via gh"
  exit 0
fi

COUNT=$(echo "$JSON" | $JQ 'length')

if [ "$COUNT" -eq 0 ]; then
  echo "MY:0 | color=green"
  echo "---"
  echo "No open PRs"
  exit 0
fi

# --- For each PR, fetch CI check status and review decision ---
# Build parallel arrays (bash 3.2 compatible — no associative arrays)
# Store results as newline-delimited records: index|ci_state|review_state
TMPFILE=$(mktemp)

echo "$JSON" | $JQ -r '.[] | "\(.repository.nameWithOwner) \(.number)"' | {
  idx=0
  while read -r nwo num; do
    (
      # Fetch checks via API
      checks_json=$($GH pr checks "$num" --repo "$nwo" --json name,state 2>/dev/null)
      checks_rc=$?

      if [ $checks_rc -ne 0 ] || [ -z "$checks_json" ] || [ "$checks_json" = "[]" ] || [ "$checks_json" = "null" ]; then
        ci_state="none"
      else
        # states: SUCCESS, FAILURE, ERROR, PENDING, CANCELLED, SKIPPED, QUEUED, ...
        has_fail=$(echo "$checks_json" | $JQ '[.[] | select(.state == "FAILURE" or .state == "ERROR" or .state == "CANCELLED")] | length')
        has_pend=$(echo "$checks_json" | $JQ '[.[] | select(.state == "PENDING" or .state == "QUEUED" or .state == "STARTUP_FAILURE")] | length')
        if [ "$has_fail" -gt 0 ]; then
          ci_state="fail"
        elif [ "$has_pend" -gt 0 ]; then
          ci_state="pending"
        else
          ci_state="pass"
        fi
      fi

      # Fetch review decision via GraphQL
      review_json=$($GH api "repos/${nwo}/pulls/${num}/reviews" --paginate 2>/dev/null)
      if [ $? -eq 0 ] && [ -n "$review_json" ] && [ "$review_json" != "[]" ]; then
        # Take the latest actionable review state per reviewer
        review_state=$(echo "$review_json" | $JQ -r '
          [.[] | select(.state != "COMMENTED" and .state != "DISMISSED" and .state != "PENDING")]
          | group_by(.user.login)
          | map(sort_by(.submitted_at) | last)
          | if any(.state == "CHANGES_REQUESTED") then "changes_requested"
            elif any(.state == "APPROVED") then "approved"
            else "none"
            end
        ')
      else
        review_state="none"
      fi

      echo "${idx}|${ci_state}|${review_state}" >> "$TMPFILE"
    ) &
    idx=$((idx + 1))
  done
  wait
}

# --- Build display data by merging PR JSON with check/review results ---
# Read the tmp file into a JSON array keyed by index
STATUS_JSON="["
first=1
while IFS='|' read -r sidx sci sreview; do
  if [ "$first" -eq 1 ]; then
    first=0
  else
    STATUS_JSON="${STATUS_JSON},"
  fi
  STATUS_JSON="${STATUS_JSON}{\"idx\":${sidx},\"ci\":\"${sci}\",\"review\":\"${sreview}\"}"
done < "$TMPFILE"
STATUS_JSON="${STATUS_JSON}]"
rm -f "$TMPFILE"

# --- Determine menu bar color ---
has_any_fail=$(echo "$STATUS_JSON" | $JQ '[.[] | select(.ci == "fail")] | length')
has_any_pend=$(echo "$STATUS_JSON" | $JQ '[.[] | select(.ci == "pending")] | length')

if [ "$has_any_fail" -gt 0 ]; then
  bar_color="red"
elif [ "$has_any_pend" -gt 0 ]; then
  bar_color="orange"
else
  bar_color="green"
fi

echo "MY:${COUNT} | color=${bar_color}"
echo "---"

# --- Render dropdown, sorted: fail first, then pending, then pass, then none ---
# Merge status into the PR JSON and sort
MERGED=$(echo "$JSON" | $JQ --argjson statuses "$STATUS_JSON" '
  [to_entries[] | . as $e |
    ($statuses[] | select(.idx == $e.key)) as $s |
    $e.value + {ci: $s.ci, review: $s.review}
  ]
  | sort_by(
      if .ci == "fail" then 0
      elif .ci == "pending" then 1
      elif .ci == "pass" then 2
      else 3
      end
    )
')

echo "$MERGED" | $JQ -r '.[] |
  # CI icon (unicode, reliable in xbar)
  (if .ci == "pass" then "✓"
   elif .ci == "fail" then "✗"
   elif .ci == "pending" then "●"
   else "?"
   end) as $ci_icon |

  # CI color
  (if .ci == "pass" then "green"
   elif .ci == "fail" then "red"
   elif .ci == "pending" then "orange"
   else "gray"
   end) as $ci_color |

  # Review label
  (if .review == "approved" then " ✔ approved"
   elif .review == "changes_requested" then " ✏ changes requested"
   else ""
   end) as $review_label |

  # Short repo name
  (.repository.name) as $repo |

  "\($ci_icon) \(.title) [\($repo)] | href=\(.url) color=\($ci_color)",
  "#\(.number)\($review_label) — \(.createdAt | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%b %d")) | size=12 color=#586069",
  "---"
'
