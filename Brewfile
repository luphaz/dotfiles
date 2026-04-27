# Cross-platform (macOS + Linuxbrew). Mac-only entries are gated with
# `if OS.mac?` so the Linux workspace install can run this Brewfile
# unchanged and skip the noise. All `cask` entries are Mac-only by
# definition (brew --cask isn't supported on Linux).

# ── Taps ─────────────────────────────────────────────────────────────
# Non-default taps used by entries below. `brew bundle` resolves taps
# before formulas, so fresh Linuxbrew installs (workspaces) get them
# added on the first run. Default taps (homebrew/core, homebrew/cask)
# are implicit and don't need declarations — bare formula/cask names
# resolve there unambiguously since core/cask names are unique within
# the registry.
tap "datadog-labs/pack"               # public DD lab org's tap — used for `pup`
tap "atlassian/acli"                  # Atlassian Connect CLI tap — used for `acli`
tap "silverstein/tap"                 # used for `minutes`

# ── Shell & Terminal ─────────────────────────────────────────────────
brew "bash"
brew "coreutils"
brew "fzf"
brew "fd"      # modern find — backs FZF_DEFAULT_COMMAND, respects .gitignore
brew "direnv"
brew "bat"
brew "bat-extras"
brew "zoxide"  # smart cd (frecency-ranked): `z <partial>` jumps to best match
brew "atuin"                          # sqlite shell history with fuzzy Ctrl+R + optional cross-machine sync
brew "atuin-server" if OS.mac?        # sync server runs on the Mac only; Linux workspaces are clients
brew "tmux"

# ── Editors & AI Coding ──────────────────────────────────────────────
brew "neovim"
brew "ollama"
brew "gemini-cli"
brew "opencode"
cask "claude-code@latest" if OS.mac?
cask "codex" if OS.mac?

# ── AI Agent Sandbox ─────────────────────────────────────────────────
brew "nono"

# ── Search & File Tools ──────────────────────────────────────────────
brew "ripgrep"
brew "ripgrep-all"
brew "wget"
brew "curl"
brew "xz"
brew "make"
brew "datadog-labs/pack/pup"          # fully-qualified to disambiguate from any homebrew-core `pup` formula and to require the datadog-labs tap declared above
brew "fswatch"

# ── Git ──────────────────────────────────────────────────────────────
brew "gh"
brew "git-delta"
brew "git-absorb"
brew "git-machete"

# ── Kubernetes & Cloud ───────────────────────────────────────────────
brew "kind"
brew "k9s"
brew "lima" if OS.mac?                # VM manager used to back rootful Docker on Mac; Linux runs Docker natively
brew "skaffold"
brew "stern"
brew "tfenv"
brew "crane"
brew "grpcurl"
brew "azure-cli"
brew "awscli"
cask "gcloud-cli" if OS.mac?

# ── Languages & Runtimes ─────────────────────────────────────────────
brew "go"
brew "gcc"
brew "uv"
brew "nvm"

# ── Linting & Code Quality ───────────────────────────────────────────
brew "shellcheck"
brew "hadolint"
brew "cue"

# ── API & Network ────────────────────────────────────────────────────
brew "httpie"
brew "w3m"

# ── Docs & Productivity ──────────────────────────────────────────────
brew "jq"
brew "tldr"
brew "hugo"
brew "adr-tools"
brew "atlassian/acli/acli" if OS.mac? # Atlassian Connect CLI — fully-qualified for clarity; tap above. Skip on Linuxbrew (no Linux formula in this tap)
brew "gnupg"
brew "silverstein/tap/minutes" if OS.mac?  # meeting-notes tool — fully-qualified; tap above. Skip on Linuxbrew

# ── Apps ─────────────────────────────────────────────────────────────
cask "xbar" if OS.mac?
cask "jordanbaird-ice" if OS.mac?     # menu bar manager: hide/reorder items, tames xbar + Control Center surface
cask "obsidian" if OS.mac?
cask "meetingbar" if OS.mac?
cask "ghostty" if OS.mac?
cask "1password-cli" if OS.mac?
