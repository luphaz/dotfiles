#!/usr/bin/env zsh

alias kg="k get"
alias kgp="kg pods -o wide"
alias kgpa="kgp --all-namespaces"
alias kgy="kg deploy -oyaml"
alias kgya="kgy --all-namespaces"
alias kpf="k port-forward"
alias kns="kubens"

unalias kl 2>/dev/null
alias kl="kubectl logs --follow --tail=5000 --max-log-requests=10"
alias kla="kl --all-containers"
alias klt="kl --prefix --timestamps"
alias klat="klt --all-containers"

kgpnl() {
  label=$1
  namespace=$2
  if [[ -n "${namespace}" ]]; then
    k get pods -oname -n="${namespace}" -l="${label}"
  else
    k get pods -oname -l="${label}"
  fi
}

alias kex="k exec -it"
kexp() {
  pod_name=$1
  shift
  cmd=$1
  shift
  k exec -it "${pod_name}" "${@}" -- "${cmd:-bash}"
}

kexl() {
  label=$1
  shift
  namespace=$1
  pod_name=$(kgpnl "${label}" "${namespace}")
  if [[ -n "${namespace}" ]]; then
    shift
    k exec -n="${namespace}" -it "${pod_name}" -- "${@:-bash}"
  else
    k exec -it "${pod_name}" -- "${@:-bash}"
  fi
}

kgpy() { kgp -oyaml "$@" | yq }
