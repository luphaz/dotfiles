# dotfiles

Personal dotfiles for macOS, managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Structure

```
dotfiles/
├── .oh-my-zsh/          # oh-my-zsh (git submodule)
├── dotbot/              # Dotbot installer (git submodule)
├── dotbot-git/          # Dotbot git plugin (git submodule)
├── git/                 # .gitconfig, .gitignore, .gitattributes
├── nvim/                # Neovim config (init.lua)
├── shell/
│   ├── .zshrc           # main shell config → linked as ~/.zshrcdotfiles
│   ├── .p10k.zsh        # Powerlevel10k theme config
│   ├── bin/             # shell utilities (tvim, fzrepl)
│   └── source/          # auto-sourced aliases & functions
│       ├── brew.zsh
│       ├── core.zsh
│       ├── git.zsh
│       ├── go.zsh
│       └── kubernetes.zsh
├── ssh/                 # SSH config → linked as ~/.ssh/config.dotfiles
├── tmux/                # .tmux.conf
├── xbar/                # xbar menu bar plugins
├── Brewfile             # Homebrew packages (brew bundle)
└── install              # bootstrap script
```

## Config layering

```
~/.zshrc                       ← managed externally; not touched by this repo
  └─ source ~/.zshrcdotfiles   ← hook appended once by ./install
       └─ shell/.zshrc         ← this repo (public config)
            └─ ~/.dd-dotfiles/init.zsh   ← private overlay (optional)
```

`~/.zshrc` is managed externally. The install script appends a single hook to source `~/.zshrcdotfiles`. Everything else lives in this repo.

## Bootstrap

```bash
mkdir -p ~/git && cd ~/git
git clone git@github.com:luphaz/dotfiles.git
cd dotfiles
./install
```

The install script will:

1. Create `~/.dotfiles → ~/git/dotfiles`
2. Initialize submodules (oh-my-zsh, dotbot, dotbot-git)
3. Clone `dd-dotfiles` private overlay if SSH access is available
4. Clone oh-my-zsh plugins (powerlevel10k, fzf-tab, fast-syntax-highlighting, forgit, jq)
5. Create all symlinks
6. Append `source ~/.zshrcdotfiles` hook to `~/.zshrc`
7. Append `Include ~/.ssh/config.dotfiles` to `~/.ssh/config`

Re-running `./install` is idempotent.

## Key tools

| Tool | What it does |
|------|-------------|
| `tvim` | Opens Neovim in a floating tmux popup (fallback to plain nvim) |
| `fzrepl` | Interactive stdin filter REPL using fzf (pipe into awk, jq, sed…) |

## Updating oh-my-zsh plugins

```bash
# Update oh-my-zsh submodule to latest
git submodule update --init --remote .oh-my-zsh

# Update a specific plugin (cloned by dotbot-git, not submodules)
git -C ~/.dotfiles/.oh-my-zsh/custom/plugins/fzf-tab pull
```
