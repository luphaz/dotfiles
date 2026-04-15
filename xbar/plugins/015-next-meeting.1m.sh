#!/usr/bin/env bash
# <xbar.title>Next Meeting</xbar.title>
# <xbar.version>v1.1</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Shows time until next calendar meeting with countdown and Zoom/Meet links</xbar.desc>
# <xbar.dependencies>jq,swift</xbar.dependencies>

JQ=/opt/homebrew/bin/jq
NOW_EPOCH=$(date +%s)

# Fetch events via Swift/EventKit (fast, no hanging)
EVENTS_JSON=$(/usr/bin/swift - 2>/dev/null <<'SWIFT'
import EventKit
import Foundation

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)
var granted = false

store.requestFullAccessToEvents { g, _ in
    granted = g
    semaphore.signal()
}
semaphore.wait()

guard granted else {
    print("[]")
    exit(0)
}

let now = Date()
let later = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
let predicate = store.predicateForEvents(withStart: now, end: later, calendars: nil)
let events = store.events(matching: predicate)
    .filter { !$0.isAllDay }
    .sorted { $0.startDate < $1.startDate }
    .prefix(5)

var results: [[String: Any]] = []
for ev in events {
    results.append([
        "title": ev.title ?? "",
        "start": Int(ev.startDate.timeIntervalSince1970 * 1000),
        "end": Int(ev.endDate.timeIntervalSince1970 * 1000),
        "location": ev.location ?? "",
        "notes": String((ev.notes ?? "").prefix(500)),
        "url": ev.url?.absoluteString ?? ""
    ])
}

let json = try! JSONSerialization.data(withJSONObject: results)
print(String(data: json, encoding: .utf8)!)
SWIFT
)

# Validate
if ! echo "$EVENTS_JSON" | $JQ empty 2>/dev/null; then
  echo "📅 ?? | color=red"
  echo "---"
  echo "Error reading calendar"
  exit 0
fi

EVENT_COUNT=$(echo "$EVENTS_JSON" | $JQ 'length')

if [ "$EVENT_COUNT" -eq 0 ]; then
  echo "📅 -- | color=#586069"
  echo "---"
  echo "No meetings in the next 2 hours | color=#586069"
  exit 0
fi

# Countdown to first event
FIRST_START_S=$(echo "$EVENTS_JSON" | $JQ -r '.[0].start / 1000 | floor')
DIFF_S=$((FIRST_START_S - NOW_EPOCH))
if [ "$DIFF_S" -lt 0 ]; then DIFF_S=0; fi
DIFF_M=$((DIFF_S / 60))
HOURS=$((DIFF_M / 60))
MINS=$((DIFF_M % 60))

if [ "$HOURS" -gt 0 ]; then
  COUNTDOWN="${HOURS}h$(printf '%02d' "$MINS")m"
else
  COUNTDOWN="${MINS}m"
fi

if [ "$DIFF_M" -lt 5 ]; then
  echo "📅 ${COUNTDOWN} | color=red"
elif [ "$DIFF_M" -lt 15 ]; then
  echo "📅 ${COUNTDOWN} | color=orange"
else
  echo "📅 ${COUNTDOWN}"
fi

echo "---"

# Extract meeting link from location/notes/url
extract_link() {
  local loc="$1" notes="$2" url="$3"
  for field in "$url" "$loc" "$notes"; do
    link=$(echo "$field" | grep -oiE 'https://[^ ]*zoom\.us/j/[^ ]*|https://meet\.google\.com/[^ ]*' | head -1)
    if [ -n "$link" ]; then echo "$link"; return; fi
  done
}

# Display each event
IDX=0
while [ "$IDX" -lt "$EVENT_COUNT" ]; do
  TITLE=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].title // \"No title\"" | cut -c1-50)
  START_MS=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].start")
  END_MS=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].end")
  LOCATION=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].location // \"\"")
  NOTES=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].notes // \"\"")
  URL=$(echo "$EVENTS_JSON" | $JQ -r ".[$IDX].url // \"\"")

  START_TIME=$(date -r $((START_MS / 1000)) "+%H:%M")
  END_TIME=$(date -r $((END_MS / 1000)) "+%H:%M")

  EVT_DIFF_M=$(( (START_MS / 1000 - NOW_EPOCH) / 60 ))
  EVT_COLOR=""
  if [ "$EVT_DIFF_M" -lt 5 ]; then
    EVT_COLOR=" color=red"
  elif [ "$EVT_DIFF_M" -lt 15 ]; then
    EVT_COLOR=" color=orange"
  fi

  echo "${TITLE} |${EVT_COLOR}"
  echo "--${START_TIME} - ${END_TIME} | size=12 color=#586069"

  MEETING_LINK=$(extract_link "$LOCATION" "$NOTES" "$URL")
  if [ -n "$MEETING_LINK" ]; then
    echo "--Join Meeting | href=${MEETING_LINK} color=#1a7cff"
  fi

  if [ -n "$LOCATION" ] && [ "$LOCATION" != "null" ] && [ "$LOCATION" != "" ]; then
    if ! echo "$LOCATION" | grep -qiE '^https://'; then
      echo "--${LOCATION:0:60} | size=11 color=#586069"
    fi
  fi

  echo "---"
  IDX=$((IDX + 1))
done
