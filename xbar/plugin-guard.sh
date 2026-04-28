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
#   1. Set strict shell mode (`-euo pipefail`) so plugins fail fast on
#      unset vars, broken pipes, and command errors. Plugins inherit
#      this via `source` — no need to repeat in each plugin file.
#   2. Append stderr to ~/Library/Logs/xbar/<plugin>.log (standard
#      macOS log location — Console.app picks it up under
#      User Reports). Append-not-truncate so a successful run after a
#      failure doesn't wipe the failure context. Size-capped at 200KB
#      tail so logs don't grow forever.
#   3. On non-zero exit, emit a dropdown ⚠ menu entry showing exit
#      code, timestamp, and the last 10 lines of stderr inline.
#      Provide "Open log" / "Reveal in Finder" actions for the full
#      history. Exit 0 so xbar treats the plugin as successful and
#      continues to the next one.
#
# Usage in a plugin:
#
#   #!/usr/bin/env bash
#   # <xbar.title>…</xbar.title>
#   source "$HOME/.dotfiles/xbar/plugin-guard.sh"
#   # …rest of plugin (already running with -euo pipefail)…

set -euo pipefail

_xbar_name=$(basename "$0" .sh)
_xbar_log_dir="$HOME/Library/Logs/xbar"
mkdir -p "$_xbar_log_dir"
_xbar_log="$_xbar_log_dir/${_xbar_name}.log"

# Per-run header so a long log stays readable: each run starts with a
# timestamped marker, errors below it belong to that run.
printf '\n── %s ──\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$_xbar_log"

# Append stderr to the log; xbar swallows stderr from plugins, so this
# is the only place the user can see what went wrong.
exec 2>>"$_xbar_log"

_xbar_size_cap=200000   # bytes; ~3000 lines of typical stderr
_xbar_trim_log() {
  local size
  size=$(wc -c <"$_xbar_log" 2>/dev/null || echo 0)
  [ "$size" -gt "$_xbar_size_cap" ] || return 0
  tail -c "$_xbar_size_cap" "$_xbar_log" >"${_xbar_log}.tmp" \
    && mv "${_xbar_log}.tmp" "$_xbar_log"
}

# ERR trap: log the failing command + line BEFORE set -e exits the shell.
# Without this, a silent failure (e.g. `grep -c PATTERN` on no match — exits 1
# but produces no stderr) leaves only a bare "── exit N ──" in the log with no
# clue which line aborted. `set -E` propagates the trap into functions and
# subshells. `${BASH_SOURCE[1]##*/}` is the plugin filename (the guard itself
# is BASH_SOURCE[0]); falls back to the guard's name if called from top level.
set -E
_xbar_on_err() {
  local rc=$? line=$1 cmd=$2
  printf '── err rc=%d at %s:%d ──\n  %s\n' \
    "$rc" "${BASH_SOURCE[1]##*/}" "$line" "$cmd" >>"$_xbar_log"
}
trap '_xbar_on_err "$LINENO" "$BASH_COMMAND"' ERR

_xbar_guard() {
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    _xbar_trim_log
    return
  fi
  # Don't re-trap from inside the trap; reset to default.
  trap - EXIT
  printf -- '── exit %d ──\n' "$rc" >>"$_xbar_log"
  _xbar_trim_log

  # Dropdown=true so the user can click ⚠ and see the context inline
  # without opening any external app.
  printf '⚠ %s | color=#f97583 dropdown=true\n' "$_xbar_name"
  printf '%s\n' '---'
  printf 'exit %d at %s\n' "$rc" "$(date '+%H:%M:%S')"
  printf '%s\n' '---'
  if [ -s "$_xbar_log" ]; then
    # Last 10 lines surfaced inline. font=Menlo + size=11 keeps stderr
    # readable when it has structured output (json, indented errors).
    tail -10 "$_xbar_log" | while IFS= read -r line; do
      printf '%s | size=11 color=#8b949e font=Menlo\n' "$line"
    done
  fi
  printf '%s\n' '---'
  # `open` resolves the user's default .log app — usually Console.app
  # on macOS, which then offers search/filter over the full history.
  printf 'Open log | shell=open param1=%s terminal=false\n' "$_xbar_log"
  printf 'Reveal log in Finder | shell=open param1=-R param2=%s terminal=false\n' "$_xbar_log"
  exit 0
}
trap _xbar_guard EXIT
