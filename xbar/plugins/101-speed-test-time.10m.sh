#!/usr/bin/env bash
# <xbar.title>Network Speed Test</xbar.title>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Use macOS networkQuality to perform a regular speed test</xbar.desc>

RESULT=$(/usr/bin/networkQuality -s 2>&1)

if [ $? -ne 0 ]; then
  echo "⚡ err | color=red"
  echo "---"
  echo "networkQuality failed"
  exit 0
fi

DOWN=$(echo "$RESULT" | grep "Downlink capacity" | awk '{print $3 " " $4}')
UP=$(echo "$RESULT" | grep "Uplink capacity" | awk '{print $3 " " $4}')
LATENCY=$(echo "$RESULT" | grep "Idle Latency" | awk '{print $3 " " $4}')

echo "⚡↓${DOWN} ↑${UP} | dropdown=false"
echo "---"
echo "$RESULT" | sed 's/|/∣/g' | while IFS= read -r line; do
  echo "$line | trim=false"
done
