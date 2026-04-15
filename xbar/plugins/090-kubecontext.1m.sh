#!/usr/bin/env bash
# <xbar.title>Kubeconfig Context Changer</xbar.title>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>luphaz</xbar.author>
# <xbar.author.github>luphaz</xbar.author.github>
# <xbar.desc>Displays active kubeconfig context and allows you to easily change contexts.</xbar.desc>
# <xbar.dependencies>kubectl</xbar.dependencies>

KUBECTL=/opt/homebrew/bin/kubectl

ACTIVE=$($KUBECTL config current-context 2>/dev/null || echo "CONTEXT_NOT_SET")
COLOR=""
case "$ACTIVE" in
  *prod.dog*) COLOR=" | color=#f97583" ;;
  *staging*)  COLOR=" | color=#ffab70" ;;
esac
echo "${ACTIVE}${COLOR}"
echo "---"

$KUBECTL config get-contexts --no-headers -o name 2>/dev/null | sort | while read -r CTX; do
  COLOR=""
  case "$CTX" in
    *prod.dog*) COLOR=" color=#f97583" ;;
    *staging*)  COLOR=" color=#ffab70" ;;
  esac
  echo "$CTX |${COLOR} bash=$KUBECTL param1=config param2=use-context param3=$CTX terminal=false"
done
