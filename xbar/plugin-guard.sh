#!/usr/bin/env bash
# This file is sourced (never executed) — the shebang is here only so the
# CI lint job (which discovers shell scripts by shebang) picks it up.
#
# xbar/plugin-guard.sh — source near the top of every xbar plugin.
#
# xbar has no per-plugin isolation: the first plugin that writes to stderr
# or exits non-zero silently kills rendering for every plugin after it
# (alphabetical order by filename). Since xbar itself is no longer
# maintained, we handle isolation ourselves at the plugin layer:
#
#   1. Redirect stderr to /tmp/xbar-<plugin>.log so transient warnings
#      (BSD comm's "not in sorted order", curl timeouts, etc.) don't
#      leak into xbar's pipeline.
#   2. On non-zero exit, emit a visible ⚠ menu entry showing the exit
#      code and the last few stderr lines, then exit 0 so xbar treats
#      the plugin as successful and continues to the next one.
#
# Usage in a plugin:
#
#   #!/usr/bin/env bash
#   # <xbar.title>…</xbar.title>
#   source "$HOME/.dotfiles/xbar/plugin-guard.sh"
#   # …rest of plugin…

_xbar_name=$(basename "$0" .sh)
_xbar_log="/tmp/xbar-${_xbar_name}.log"
exec 2>"$_xbar_log"

_xbar_guard() {
  local rc=$?
  [ "$rc" -eq 0 ] && return
  # Don't re-trap from inside the trap; reset to default.
  trap - EXIT
  printf '⚠ %s | color=#f97583 dropdown=false\n' "$_xbar_name"
  printf '%s\n' '---'
  printf 'exit %d — tail of stderr:\n' "$rc"
  if [ -s "$_xbar_log" ]; then
    tail -3 "$_xbar_log" | while IFS= read -r line; do
      printf '%s | size=11 color=#8b949e\n' "$line"
    done
  fi
  printf 'Open log | bash=open param1=%s terminal=false\n' "$_xbar_log"
  exit 0
}
trap _xbar_guard EXIT
