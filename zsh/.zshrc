# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.dotfiles/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Those plugins can be installed using brew install
# Let's direclty source them here to ensure this configuration is as portable as possible
# They should not been referenced into the standard oh-my-zsh plugins below
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /usr/local/share/zsh/site-functions

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(

  git
  kubectl
  helm
  docker

  # dcup \o/
  docker-compose
)

source "${ZSH}/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/id_rsa"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

DEFAULT_USER=$(id -un)

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context kubecontext dir rbenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time battery)
POWERLEVEL9K_TIME_BACKGROUND='025'

POWERLEVEL9K_KUBECONTEXT_FOREGROUND='233'
POWERLEVEL9K_KUBECONTEXT_BACKGROUND='008'

POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_DELIMITER=""
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"

# Add asdf from brew BEFORE any aliases
if [[ -z "${ASDF_DIR}" ]]; then
  asdf_folder="/usr/local/Cellar/asdf"
  asdf_version="$(ls "${asdf_folder}" | tail -n1)"
  export ASDF_DIR="${asdf_folder}/${asdf_version}/libexec"
  [[ -f $(brew --prefix asdf)/asdf.sh ]] && source $(brew --prefix asdf)/asdf.sh
fi

# GITPATH private location hidden
export GITPATH="$HOME/Git"

# Useful for gotools through asdf
# if [[ -z "${GOROOT}" ]]; then
#   GOV=$(asdf where golang)
#   if [[ "$GOV" != "Version not installed" ]]; then
#     export GOROOT="$GOV/go"
#   fi
# fi

# GOPATH to store vendor into
export GOPATH="${GITPATH}/Go"

# Go shortcut to jump
export GOPERSO="${GOPATH}/src/github.com/luphaz/"

# source lazy aliases and funcs
[[ -f "$HOME/.dotfiles/zsh/private.zsh" ]] && . "$HOME/.dotfiles/zsh/private.zsh"
[[ -f "$HOME/.dotfiles/zsh/lazy.zsh" ]] && . "$HOME/.dotfiles/zsh/lazy.zsh"

prepend_path() {
  if [[ ! "${PATH}" =~ $1 ]]; then
    PATH="$1:$PATH"
  fi
}

# https://github.com/sindresorhus/guides/blob/master/npm-global-without-sudo.md
export NPM_PACKAGES="${HOME}/.npm-packages"
prepend_path "${NPM_PACKAGES}/bin"
unset MANPATH
export MANPATH="$NPM_PACKAGES/share/man:$(manpath)"

# Path concatenation, because path is never enough
# export PATH="/usr/local/opt/gnu-getopt/bin:/usr/local/opt/python@3.7/bin:${PATH}:${NPM_PACKAGES}/bin:${GOPATH}/bin"
prepend_path "${GOPATH}/bin:/usr/local/opt/gnu-getopt/bin"

# PROTOBUF RELATED CONFIGURATION
# If you need to have protobuf@3.6 first in your PATH, run:
prepend_path "/usr/local/opt/protobuf@3.6/bin"

# Used for mssh (EC2InstanceConnect)
prepend_path "/Users/matthieu.bono.heetch/Library/Python/3.8/bin"

# For compilers to find protobuf@3.6 you may need to set:
export LDFLAGS="-L/usr/local/opt/protobuf@3.6/lib"
export CPPFLAGS="-I/usr/local/opt/protobuf@3.6/include"

#For pkg-config to find protobuf@3.6 you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/protobuf@3.6/lib/pkgconfig"

# Awesome trick to auto-complete directory you go often, any directory behind Git/Go/Home is just one `cd dir-name` aways
GITWORKTREES="$HOME/Git/worktrees"
cdpath=($HOME $GITPATH $GOCOMPANY $GOPERSO $GODRONE $GITWORKTREES)

# Useful to speedup docker at some point
#export NO_PROXY=*

# Ensure apps run using dev configuration by default
export ENVIRONMENT=development
export KUBE_EDITOR='code --wait'

# let's have some color when diffing Kubernetes files through kubectl diff...
# export KUBECTL_EXTERNAL_DIFF="colordiff  --side-by-side --suppress-common-lines"
export KUBECTL_EXTERNAL_DIFF="dyff between --omit-header --set-exit-code"

# Fuzzy finding configuration if exists
[[ -f "$HOME/.fzf.zsh" ]] && . "$HOME/.fzf.zsh"

# Stern is useful to concatenate k8s logs
# source <(stern --completion=zsh)

# iterm2 default keybindings sucks, use info provided here to update the keybinding to a more natural one (if it suits you of course)
# https://gist.github.com/kevin-smets/8568070

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && . "$HOME/.fig/shell/zshrc.post.zsh"
