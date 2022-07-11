#!/usr/bin/env zsh -ex

# Used to edit current directory into VSCode
alias c="code ."

# Used to edit "root directory"
cr() {code $(git root)}

# Used to move to the "root directory"
cdr() {cd $(git root)}

# Used to edit quickly zshrc into VSCode
alias ez="code ~/.dotfiles/zsh/lazy.zsh ~/.dotfiles/zsh/.zshrc ~/.dotfiles ~/.dotfiles/git/.gitconfig"

# Kill all jobs in background using a do while like loop
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

# Used to run minikube shortly
alias mk=minikube

# Used to run isopod shortly
alias i=isopod

# Used to run istioctl shortly
alias ist=istioctl

# Used to run docker shortly
alias d=docker

# Used to run git shortly
alias g=git

# User to run vim shortly
alias v=vim

alias gh="GITHUB_TOKEN='' gh"

# Because colored git diff is way better that default diff available on MacOS
alias diff="git diff"

# retrieve default branch
gdbr() {
  git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

alias git-remote-set-head="git remote set-head origin master"

unalias gcm
gcm() {
  git checkout $(gdbr) "$@"
}

# retrieve current branch
alias gcbr="git rev-parse --abbrev-ref HEAD"

# Used to create a github pull request
alias gprc='gh pr create --web'
# alias gprc='gh pr create --web --title "$(git log -1 --pretty=%B)"'

# Create a pull request using first commit message
alias gprf="hub pull-request --no-edit"

# Create a pull request using last commit message
alias gprl='hub pull-request -m "$(git log -1 --pretty=%B)"'

# Open branch pull request in web
alias gpro="gh pr view --web"

# View branch pull request in terminal
alias gprv="gh pr view"

# list worktree branches
alias gwl="git worktree list"

# Used to rebase origin/defaultBranch into current branch
unalias grbom
grbom() {
  git rebase "origin/$(gdbr)" "$@"
}

# rebase preferring origin/gbdr changes merge during conflicts
grbom-favor-master() {
  grbom -Xours
}

# rebase preferring current branch changes merge during conflicts
grbom-favor-branch() {
  grbom -Xtheirs
}

# Used to interactive rebase from origin/defaultBranch to simply reorder/drop commits before PR
grbiom() {
  grbi "origin/$(gdbr)" "$@"
}

grb-child() {
  parent_branch="$1"
  shift
  git rebase origin/master --onto "${parent_branch}" -Xours "$@"
}

# Used to git diff origin/defaultbranch
gdom() {
  git diff "origin/$(gdbr)" "$@"
}

# Used to git diff origin/currentBranch
gdo() {
  git diff "origin/$(gcbr)" "$@"
}

# Used to reset from origin/defaultbranch
grom() {
  git reset "origin/$(gdbr)" "$@"
}

# Used to reset from origin/defaultbranch HARD
gromh() {
  git reset "origin/$(gdbr)" --hard "$@"
}

# Used to go to defaultbranch, fetch all prune, and pull
alias gfm="gfa && gcm && gl"

# Used to get ...
alias kg="k get"

# Used to get all pods
alias kgp="k get pods -o wide"

# Used to get deployment spec as yaml
alias kgy="k get deploy -oyaml"

# Used to get deployment spec as yaml for all namespaces
alias kgya="kgy --all-namespaces"

# Used to shorten the port forward command :
alias kpf="k port-forward"

# Used to shorten the kubectl exec command :
alias kex="k exec -it"

# Used to get all pods on all namespaces
alias kgpa="kgp --all-namespaces"

# Use to clean docker images & instance unused
alias dclean="docker run --rm --privileged=true -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc:ro spotify/docker-gc"

# Shorten docker-compose command
alias dc="docker-compose"

# Provide retro-compatibility
alias kctx="kubectx"

# Provide retro-compatibility
alias kns="kubens"

# Force grep color and insensitive by default
alias grep="grep --color=auto -i"

# See all commits that contain the string $1 in their diff
git-dig() {
  git log --pretty=format:'%Cred%h%Creset - %Cgreen(%ad)%Creset - %s %C(bold blue)<%an>%Creset' --abbrev-commit --date=short -G"$1" -- $2
}

# list direct outdated goland packages
alias go-out="go list -u -m -json all | go-mod-outdated -update -direct"

# list direct packages
go-direct() {
  go list -f '{{if not .Indirect}}{{.}}{{end}}' -u -m all | tail -n+2 | cut -d" " -f1
}

# update direct packages to latest version
go-up() {
  exclude="${1}"
  for package in $(go-direct); do
    if [[ "${exclude}" != *"${package}"* ]]; then
      echo "updating package: ${package}@latest..."
      go get -d "${package}@latest"
    else
      echo "${package} skipped to be updated because part of provided exclusion: ${exclude}"
    fi
  done
  go mod tidy -v
}

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Used to update the current or given branch and push changes remotely
unalias gup
gup() {
  if [[ -n "$1" ]]; then
    gco "$1"
  fi

  gfa && grbom && g pf
}

unalias kl
kl() {
  kubectl logs --follow --timestamps --all-containers --prefix --since 1h --tail 20 --max-log-requests=10 "$@"
}

alias gw="git worktree"

# Used to create a new branch with an up to date defaultBranch (and all tracked branches)
# possible to give a jira link or directly branch name
gn() {
  gfm
  gcb "$(jira-branch-name "$1" "$2")"
}
