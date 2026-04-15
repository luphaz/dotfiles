# ~/.zshrcdotfiles — sourced from ~/.zshrc
# p10k instant prompt must stay in ~/.zshrc (before this file is sourced)

# Homebrew
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_DIR=/opt/homebrew
export HOMEBREW_BIN=/opt/homebrew/bin

# Prefer GNU binaries
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}"

# Go
export GOPATH="${HOME}/go"
export PATH="${GOPATH}/bin:${PATH}"

export PATH="${HOME}/.dotfiles/shell/bin:${PATH}"

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Auto-start tmux with a unique session name
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
  exec tmux new
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.dotfiles/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(
  fzf-tab                  # https://github.com/Aloxaf/fzf-tab#install
  fast-syntax-highlighting # https://github.com/zdharma-continuum/fast-syntax-highlighting

  git
  forgit # https://github.com/wfxr/forgit
  kubectl
  helm
  docker
  jq # https://github.com/reegnz/jq-zsh-plugin + iTerm2 send escape sequence CMD+J --> j + see below for CTRL+J (bindkey)
)

# Add completion paths BEFORE oh-my-zsh's compinit (so one compinit covers all)
fpath=(/opt/homebrew/share/zsh/site-functions "${HOME}/.docker/completions" $fpath)

source "${ZSH}/oh-my-zsh.sh"

# google-cloud-sdk (after oh-my-zsh so compdef is already available — no extra compinit)
[[ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ]] && \
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
[[ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]] && \
  source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc

# required to load zsh-autosuggestions AFTER fzf-tab https://github.com/Aloxaf/fzf-tab#install
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

# Source private dotfiles overlay if available
[[ -f ~/.dd-dotfiles/init.zsh ]] && source ~/.dd-dotfiles/init.zsh

# brew fpath + compinit moved above oh-my-zsh source (single compinit)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Created by `pipx`
export PATH="$PATH:$HOME/.local/bin"
