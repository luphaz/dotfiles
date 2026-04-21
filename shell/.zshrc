# ~/.zshrcdotfiles — sourced from ~/.zshrc
# p10k instant prompt must stay in ~/.zshrc (before this file is sourced)

# Homebrew — OS-aware prefix
if [[ "$(uname)" == "Darwin" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
else
  export HOMEBREW_PREFIX="${HOME}/.linuxbrew"
fi
export PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_DIR="${HOMEBREW_PREFIX}"
export HOMEBREW_BIN="${HOMEBREW_PREFIX}/bin"

# Prefer GNU binaries (macOS only — Linux already uses GNU coreutils)
[[ "$(uname)" == "Darwin" ]] && export PATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin:${PATH}"

# Use 1Password as the SSH agent (macOS only).
# ~/.ssh/ssh_auth_sock is a stable symlink to the 1Password socket — avoids a
# path with spaces ("Group Containers") that tmux's update-environment and
# some tools (e.g. workspaces CLI's Go SSH client) don't handle reliably.
if [[ "$(uname)" == "Darwin" ]]; then
  [[ "$(readlink "${HOME}/.ssh/ssh_auth_sock" 2>/dev/null)" == "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]] \
    || ln -sf "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" "${HOME}/.ssh/ssh_auth_sock"
  export SSH_AUTH_SOCK="${HOME}/.ssh/ssh_auth_sock"
fi

# Go
export GOPATH="${HOME}/go"
export PATH="${GOPATH}/bin:${PATH}"

export PATH="${HOME}/.dotfiles/shell/bin:${PATH}"

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export FZF_DEFAULT_OPTS='--cycle'

# Back fzf with fd so file/dir pickers skip .git, node_modules, etc. (respects .gitignore).
# Guarded: if fd isn't installed yet (pre-Brewfile bootstrap), fzf falls back to its builtin walker.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.dotfiles/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(
  fzf-tab                  # https://github.com/Aloxaf/fzf-tab#install
  fast-syntax-highlighting # https://github.com/zdharma-continuum/fast-syntax-highlighting
  zsh-autosuggestions      # https://github.com/zsh-users/zsh-autosuggestions — load AFTER fzf-tab & syntax highlighting

  git
  forgit # https://github.com/wfxr/forgit
  kubectl
  helm
  docker
  gcloud # portable google-cloud-sdk path + completion loader (Mac brew / Linux apt / snap)
  jq # https://github.com/reegnz/jq-zsh-plugin + iTerm2 send escape sequence CMD+J --> j + see below for CTRL+J (bindkey)
)

# Add completion paths BEFORE oh-my-zsh's compinit (so one compinit covers all)
[[ -n "$HOMEBREW_PREFIX" ]] && fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
[[ -d "${HOME}/.docker/completions" ]] && fpath=("${HOME}/.docker/completions" $fpath)

# Reset completion state when oh-my-zsh was already loaded (workspace double-load)
[[ -n "$ZSH_COMPDUMP" ]] && unset ZSH_COMPDUMP
source "${ZSH}/oh-my-zsh.sh"

bindkey '^j' jq-complete

DEFAULT_USER=$(id -un)

source ~/.p10k.zsh

export GITHUB_LOGIN=luphaz

# GITPATH private location hidden
export GITPATH="$HOME/git"

# source lazy aliases and funcs
for source in ~/.dotfiles/shell/source/*; do
  source $source
done

# Awesome trick to auto-complete directory you go often
GITWORKTREES="$HOME/Git/worktrees"
cdpath=($HOME $GITPATH $GITWORKTREES)

export KUBE_EDITOR='tvim'
export EDITOR='tvim'

# let's have some color when diffing Kubernetes files through kubectl diff...
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"

# hook direnv — cache the hook output (it's static) to avoid a 280ms subprocess
_direnv_hook_cache="${XDG_CACHE_HOME:-$HOME/.cache}/direnv-hook-zsh.sh"
if [[ ! -f "$_direnv_hook_cache" ]] || [[ "$(command -v direnv)" -nt "$_direnv_hook_cache" ]]; then
  direnv hook zsh > "$_direnv_hook_cache"
fi
source "$_direnv_hook_cache"
unset _direnv_hook_cache

# zoxide — smart `cd` with frecency ranking (`z <partial>` / `zi` for interactive).
# Init output is static per binary, so cache it like the direnv hook.
if command -v zoxide >/dev/null 2>&1; then
  _zoxide_init_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide-init-zsh.sh"
  if [[ ! -f "$_zoxide_init_cache" ]] || [[ "$(command -v zoxide)" -nt "$_zoxide_init_cache" ]]; then
    zoxide init zsh > "$_zoxide_init_cache"
  fi
  source "$_zoxide_init_cache"
  unset _zoxide_init_cache
fi

# atuin — sqlite-backed shell history with fuzzy Ctrl+R and optional sync.
# --disable-up-arrow keeps Up as plain history scroll (no fuzzy popup); only Ctrl+R is rebound.
# Run `atuin register` / `atuin login` manually to enable cross-machine sync.
if command -v atuin >/dev/null 2>&1; then
  _atuin_init_cache="${XDG_CACHE_HOME:-$HOME/.cache}/atuin-init-zsh.sh"
  if [[ ! -f "$_atuin_init_cache" ]] || [[ "$(command -v atuin)" -nt "$_atuin_init_cache" ]]; then
    atuin init zsh --disable-up-arrow > "$_atuin_init_cache"
  fi
  source "$_atuin_init_cache"
  unset _atuin_init_cache
fi

# Source private dotfiles overlay if available
[[ -f ~/.dd-dotfiles/init.zsh ]] && source ~/.dd-dotfiles/init.zsh
