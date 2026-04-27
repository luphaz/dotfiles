#!/usr/bin/env zsh

# Claude Code — always in a worktree, always via PR (consistent across repos).
# ccl: trusted full-write work. cce: read-only exploration — plan mode means
# no Edit/Write/destructive Bash; to go further claude calls ExitPlanMode
# which prompts for approval.
#
# CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 disables claude's auto-memory feature
# regardless of any per-project .claude/settings.json that tries to re-enable
# it (process env beats settings-file env at launch). Behaviour preferences
# live in CLAUDE.md, mechanical rules in PreToolUse hooks — memory recall is
# too soft a guarantee. See https://github.com/luphaz/.claude/pull/1.
ccl() {
  CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude --strict-mcp-config --worktree "$@"
}
cce() {
  CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude --permission-mode plan --worktree "$@"
}

# tmux
alias tl='tmux list-sessions -F "#{session_activity} #{session_name}: #{session_windows} windows (created #{t:session_created})#{?session_attached, (attached),}" 2>/dev/null | sort -rn | cut -d" " -f2-'

# Attach to the most recently used tmux session, or create "main" if none exist.
# Sort by session_last_attached — attach-session without -t uses creation order, not recency.
ta() {
  [[ -n "$TMUX" ]] && { echo "already in tmux: $(tmux display-message -p '#S')" >&2; return 1; }
  if tmux list-sessions &>/dev/null; then
    local last
    last=$(tmux list-sessions -F '#{session_last_attached} #{session_name}' \
      | sort -rn | head -1 | awk '{print $2}')
    tmux attach-session -t "$last"
  else
    tmux new-session -s main
  fi
}

ts() {
  local session
  session=$(tmux-ls \
    | fzf --ansi --height=40% --reverse --no-sort \
           --preview='tmux capture-pane -ep -t {-1}' \
           --preview-window=right:60% \
    | awk '{print $NF}') \
    && tmux switch-client -t "$session"
}

tk() {
  local current sessions
  current=$(tmux display-message -p '#S' 2>/dev/null)
  sessions=$(tmux-ls \
    | grep -v " ${current} " \
    | fzf --ansi --height=40% --reverse --no-sort --multi \
           --preview='tmux capture-pane -ep -t {-1}' \
           --preview-window=right:60%) \
    || return
  echo "$sessions" | awk '{print $NF}' | while read -r s; do
    tmux kill-session -t "$s" && echo "killed: $s"
  done
}

# Navigation
cdw() { cd "$(git rev-parse --show-toplevel)" }
cdr() { cd "$(cd "$(git rev-parse --git-common-dir)/.." && pwd)" }

alias ez="fb ~/.dotfiles"

# CMD+K → clear screen + scrollback, matching the tmux M-k binding.
# Ghostty forwards CMD+K as \ek (Alt+K). Inside tmux, .tmux.conf intercepts
# M-k at the root table so zsh never sees it; outside tmux, this widget fires
# and emits the ANSI sequences (ED + erase-scrollback) that Ghostty honors.
_cmd_k_clear() {
  printf '\e[H\e[2J\e[3J'
  zle reset-prompt
}
zle -N _cmd_k_clear
bindkey '\ek' _cmd_k_clear

kj() {
  jobs
  kill %
  result=$?
  while [[ $result == 0 ]]; do
    kill %
    result=$?
    echo last command result is $result
    sleep 1
  done
}

alias d=docker
alias g=git
alias v=nvim
alias i=isopod
alias dc="docker-compose"
alias dclean="docker run --rm --privileged=true -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc:ro spotify/docker-gc"
alias grep="grep --color=auto -i"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# bat
alias cat='bat --paging=never'
alias fzp="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"

# ripgrep-all + fzf
rga-fzf() {
  RG_PREFIX="rga --files-with-matches"
  local file
  file="$(
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
      fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
      --phony -q "$1" \
      --bind "change:reload:$RG_PREFIX {q}" \
      --preview-window="70%:wrap"
  )" &&
    echo "opening $file" &&
    xdg-open "$file"
}

# Process killer with fzf
pk() {
  local pids
  pids=$(ps -eo pid,user,%cpu,%mem,start,time,command | sed 1d \
    | fzf --height=40% --reverse --multi \
           --header='[tab] select · [enter] kill -9' \
           --preview='ps -p {1} -o pid,ppid,user,%cpu,%mem,vsz,rss,stat,start,time,command 2>/dev/null || echo "process exited"' \
           --preview-window=right:60% \
    | awk '{print $1}') \
    || return
  echo "$pids" | while read -r p; do
    kill -9 "$p" && echo "killed: $p"
  done
}
# fb — file browser (shell/bin/fb script, also used by Ctrl+E tmux binding)
