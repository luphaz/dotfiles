#!/usr/bin/env zsh

alias go-out="go list -u -m -json all | go-mod-outdated -update -direct"

go-direct() {
  go list -mod=readonly -f '{{if not .Indirect}}{{.}}{{end}}' -u -m all | tail -n+2 | cut -d" " -f1
}

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
