# dotfiles-step.sh — sourced by `install` and dotbot shell blocks.
# Provides: step <name> -- <cmd...>      (one-shot wrapper, used in `install`)
#           _step_begin <name>           (multi-line block start; returns 1 if skipped)
#           _step_end [state]            (multi-line block end)
#           _step_end_auto               (EXIT trap variant; preserves the rc)
#           _step_summary                (pretty-print sorted timings)
#
# Env contract:
#   DOTFILES_SKIP    Comma list of step names to skip ("brew,omz,tfenv,...").
#   DOTFILES_TIMINGS Path of an append-only TSV log "<elapsed_s>\t<state>\t<name>".
#                    Set by `install` to a tmpfile; the EXIT trap there prints a
#                    sorted summary. When unset (helper used standalone), per-step
#                    output still lands on stderr — the summary is just skipped.
#
# Wall-clock granularity is one second (`date +%s`) — plenty for surfacing the
# minute-scale steps the user cares about (brew bundle, tfenv, omz pulls), and
# avoids a python3/perl dependency for sub-second precision.
#
# Resolve `date` to its absolute path at source time and call it through
# $_DOTFILES_DATE so timing keeps working even if the calling block later
# clobbers PATH (zsh's `path` special, broken activation scripts, etc.).
# Falls back to /bin/date — present on macOS and any reasonable Linux.
_DOTFILES_DATE="$(command -v date 2>/dev/null || echo /bin/date)"

# Module-scope state used by the _step_begin / _step_end pair. Each dotbot
# shell block is its own bash invocation, so collisions between blocks are not
# possible — but we still scope the names to make sourcing into a long-lived
# shell (the top-level `install`) safe.
_DOTFILES_STEP_NAME=
_DOTFILES_STEP_START=

# _step_begin <name>
# Records the step name + start time. If <name> is in DOTFILES_SKIP, prints a
# skip notice, records a zero-duration row in DOTFILES_TIMINGS, and returns 1
# so the caller can `|| exit 0` to short-circuit the rest of the block.
_step_begin() {
  _DOTFILES_STEP_NAME="$1"
  case ",${DOTFILES_SKIP:-}," in
    *",${_DOTFILES_STEP_NAME},"*)
      printf '⏭  %-44s skipped (DOTFILES_SKIP)\n' "$_DOTFILES_STEP_NAME" >&2
      [ -n "${DOTFILES_TIMINGS:-}" ] && printf '0\tskip\t%s\n' "$_DOTFILES_STEP_NAME" >> "$DOTFILES_TIMINGS"
      return 1
      ;;
  esac
  _DOTFILES_STEP_START=$("$_DOTFILES_DATE" +%s)
  return 0
}

# _step_end [state]
# Prints elapsed and appends a row to DOTFILES_TIMINGS. Default state "ok".
# NOTE: avoid the local var name `status` — it's a read-only special in zsh
# (alias for $?), and dotbot's shell plugin runs blocks under $SHELL (zsh on
# this machine), so `local status=` would abort the whole block.
_step_end() {
  local elapsed=$(( $("$_DOTFILES_DATE" +%s) - _DOTFILES_STEP_START ))
  local state="${1:-ok}"
  printf '⏱  %-44s %ds (%s)\n' "$_DOTFILES_STEP_NAME" "$elapsed" "$state" >&2
  [ -n "${DOTFILES_TIMINGS:-}" ] && printf '%d\t%s\t%s\n' "$elapsed" "$state" "$_DOTFILES_STEP_NAME" >> "$DOTFILES_TIMINGS"
}

# _step_end_auto
# Designed to be wired as `trap _step_end_auto EXIT` inside dotbot shell blocks.
# Captures the pending exit status, formats ok/fail($rc), and delegates to
# _step_end. The bash EXIT trap does NOT override the script's actual exit
# status, so dotbot still sees the real rc — failures are recorded in the
# timing log without being masked by the trap.
_step_end_auto() {
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    _step_end ok
  else
    _step_end "fail($rc)"
  fi
}

# step <name> [--] <cmd> [args...]
# One-shot wrapper for the top-level `install` script. Honors DOTFILES_SKIP,
# captures the exit code of <cmd>, records timing, and propagates the rc.
step() {
  local name="$1"; shift
  [ "${1:-}" = "--" ] && shift
  if ! _step_begin "$name"; then
    return 0
  fi
  local rc=0
  "$@" || rc=$?
  if [ "$rc" -eq 0 ]; then
    _step_end ok
  else
    _step_end "fail($rc)"
  fi
  return "$rc"
}

# _step_summary [install_start_epoch]
# Pretty-prints the DOTFILES_TIMINGS log sorted slowest-first. No-op when the
# file is unset, missing, or empty (e.g. every step skipped or library sourced
# without `install` setting up the log). When passed an install-start epoch,
# also prints true wall-clock — note that summing every row would double-count
# (the top-level `dotbot-main` row wraps the seven inner block rows it spawns).
_step_summary() {
  [ -z "${DOTFILES_TIMINGS:-}" ] && return 0
  [ ! -s "$DOTFILES_TIMINGS" ] && return 0
  local install_start="${1:-}"
  echo
  echo "── Install timing summary ──────────────────────────────────"
  printf '%6s  %-9s  %s\n' "TIME" "STATE" "STEP"
  sort -k1,1 -nr "$DOTFILES_TIMINGS" | while IFS=$'\t' read -r elapsed state name; do
    printf '%5ds  %-9s  %s\n' "$elapsed" "$state" "$name"
  done
  echo "────────────────────────────────────────────────────────────"
  if [ -n "$install_start" ]; then
    local wall=$(( $("$_DOTFILES_DATE" +%s) - install_start ))
    printf 'Wall clock: %ds\n' "$wall"
  fi
  echo "Skip slow steps with: DOTFILES_SKIP=name1,name2 ./install"
}
