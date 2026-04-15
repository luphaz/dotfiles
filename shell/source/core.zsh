#!/usr/bin/env zsh

# Claude Code
alias ccl='claude --tmux=classic --worktree --strict-mcp-config'
alias cce='claude --tmux=classic --worktree'

# tmux
alias tl='tmux list-sessions -F "#{session_activity} #{session_name}: #{session_windows} windows (created #{t:session_created})#{?session_attached, (attached),}" 2>/dev/null | sort -rn | cut -d" " -f2-'

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
