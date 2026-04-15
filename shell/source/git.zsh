#!/usr/bin/env zsh -ex

# some aliases here suppose zsh plugins "git" has been added

# overall workflow once inside a git repository:
# 1. gn https://JIRA-URL/JIRA-1234 small-desc # fetch remote latest changes create a branch and jump into it
#     $(whoami)/JIRA-1234/small-desc
# 2. ga|gapa . # add files (ga) with partial changes (gapa)
# 3. gcmsg "feat(scope): new state of things" # commit staged file using conventionnal commits https://www.conventionalcommits.org/en/v1.0.0-beta.4/#specification
# ...
# 4. gob|goba # automatically add new changes to already existing commits
# ...
# 5. gfu # manually add changes to previously existing commit, using fzf as preview/selector for git commits, suppose forgit https://github.com/wfxr/forgit
# ...
# 6. gprc # create a new draft PR using GitHUB UI assigning me, provide $1 if you have a base branch different than default branch
# ...
# 7. gup # rebase current branch with latest changes from default branch and push them remotely, with lease
# ...
# 8. gpro # open current PR into web browser, review desc, and open for review

alias g=git

# get default branch (main, master, ...)
gdbr() {
  git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

# get current branch
alias gcbr="git rev-parse --abbrev-ref HEAD"

git-remote-set-head() {
  git remote set-head origin $(gcbr)
}

# checkout default branch
# you can provide more args like --force (at your own risks)
unalias gcm 2>/dev/null
gcm() {
  git checkout $(gdbr) "$@"
}

# Used to create a github pull request, if you have a single commit it's better
gprc() {
  gh pr create --web --assignee=@me --fill --base=${1:-$(gdbr)}
}
# alias gprc='gh pr create --web --title "$(git log -1 --pretty=%B)"'

# Open branch pull request in web
alias gpro="gh pr view --web"

# View branch pull request in terminal
alias gprv="gh pr view"

# Used to rebase origin/defaultBranch onto current branch
unalias grbom 2>/dev/null
grbom() {
  git rebase "origin/$(gdbr)" "$@"
}

# install git-absorb and ✨
# workflow is
# create some commit as usual
# add more changes
# gob || goba # create commits to be fixup with existing commits, may fail if no match found
# goto # at some point, you can use gob/goba several times before
# will present VSCode to confirm all fixup commits order, just validate
gob() {
  gsc && git-absorb --and-rebase --base $(gdbr) && gusc
}

goba() {
  git add . && gob
}

alias goto="grbiom --autosquash"

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
  grbi --autosquash "origin/$(gdbr)" "$@"
}

# rebase current branch onto $1 provided branch (current branch is considered child of provided branch)
grb-child() {
  parent_branch="$1"
  shift
  git rebase "origin/$(gdbr)" --onto "${parent_branch}" -Xours "$@"
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
  grom --hard "$@"
}

# groc to reset from origin/currentBranch
groc() {
  git reset "origin/$(gcbr)" "$@"
}

# groch to reset from origin/currentBranch HARD
groch() {
  groc --hard "$@"
}

# gsc stash current changes that are not staged, including not tracked files and ignored files
gsc() {
  git stash save --keep-index --include-untracked --all
}

# Used to fetch all prune, go to defaultbranch, and pull, ready to start new work from up to date clean defaultBranch version
alias gfm="gfa && gcm && gl"

# See all commits that contain the string $1 in their diff
git-dig() {
  git log --pretty=format:'%Cred%h%Creset - %Cgreen(%ad)%Creset - %s %C(bold blue)<%an>%Creset' --abbrev-commit --date=short -G"$1" -- $2
}

# Used to update the current or given branch and push changes remotely (wipe remote if no changes )
unalias gup 2>/dev/null
gup() {
  if [[ -n "$1" ]]; then
    gco "$1"
  fi

  gfa && grbom && gpf
}

jira-branch-name() {
  # retrieve JIRA ticket name from an URL https://XXX.atlassian.net/browse/PROJECT_ID-335 --> PROJECT_ID-335
  jira_ticket_id="${1##*/}"
  context_to_add="$2"
  echo "$(whoami)/${jira_ticket_id}/${context_to_add}"
}

# Used to create a new branch with an up to date defaultBranch (and all tracked branches)
# possible to give a jira link or directly branch name
# if jira-branch-name func exists it will use it to extract branch
gn() {
  gfm && git machete add -y "$(jira-branch-name "$1" "$2")"
}

gnc() {
  git machete add -y "$(jira-branch-name "$1" "$2")"
}

grbi-machete() {
  git machete reapply
}

# Worktree
alias gw="git worktree"
alias gwl="gw list"

# Remove current worktree, delete its branch, and prune stale references
gwr() {
  local wt_path branch repo_root
  wt_path=$(git rev-parse --show-toplevel)
  branch=$(git rev-parse --abbrev-ref HEAD)
  repo_root=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)

  if [[ "$wt_path" == "$repo_root" ]]; then
    echo "error: already in main worktree, nothing to remove" >&2
    return 1
  fi

  cd "$repo_root" || return 1
  git worktree remove "$wt_path" || return 1
  git worktree prune
  echo "removed worktree: $wt_path"

  if git rev-parse --verify "$branch" &>/dev/null; then
    git branch -D "$branch" && echo "deleted branch: $branch"
  fi
}
# Remove all worktrees whose branch has been merged (squash or regular)
gwc() {
  local repo_root default_branch
  repo_root=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
  cd "$repo_root" || return 1

  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  default_branch=${default_branch:-main}
  git fetch --prune origin 2>/dev/null

  local removed=0
  while read -r wt_path _hash wt_ref; do
    [[ "$wt_path" == "$repo_root" ]] && continue
    [[ "$wt_ref" != \[* ]] && continue

    local branch=${wt_ref#\[}
    branch=${branch%\]}

    local merged=false
    # Check via gh PR state (catches squash merges)
    if gh pr view "$branch" --json state -q .state 2>/dev/null | grep -q MERGED; then
      merged=true
    # Fallback: check if branch is reachable from default branch (regular merges)
    elif git branch --merged "origin/$default_branch" 2>/dev/null | grep -qw "$branch"; then
      merged=true
    fi

    if $merged; then
      echo "removing: $branch (merged)"
      git worktree remove "$wt_path" && git branch -D "$branch" 2>/dev/null
      ((removed++))
    else
      echo "keeping: $branch"
    fi
  done < <(git worktree list)

  git worktree prune
  echo "done: removed $removed worktree(s)"
}

alias git-branch-delete-gone="git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D"
