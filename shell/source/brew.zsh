#!/usr/bin/env zsh

# [B]rew [C]lean [P]lugin — uninstall with fzf
bcp() {
  local uninst=$(brew leaves | eval "fzf ${FZF_DEFAULT_OPTS} -m --header='[brew:clean]'")
  if [[ $uninst ]]; then
    for prog in $(echo $uninst); do brew uninstall $prog; done
  fi
}

# [B]rew [I]nstall [P]lugin — install with fzf
bip() {
  local inst=$(brew search | eval "fzf ${FZF_DEFAULT_OPTS} -m --header='[brew:install]'")
  if [[ $inst ]]; then
    for prog in $(echo $inst); do brew install $prog; done
  fi
}

# [B]rew [U]pdate [P]lugin — upgrade with fzf
bup() {
  local upd=$(brew leaves | eval "fzf ${FZF_DEFAULT_OPTS} -m --header='[brew:update]'")
  if [[ $upd ]]; then
    for prog in $(echo $upd); do brew upgrade $prog; done
  fi
}
