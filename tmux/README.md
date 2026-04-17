# tmux config — binding reference

Companion to [`.tmux.conf`](./.tmux.conf). The config itself stays terse; this
README exists to remind **future-me** *why* each binding exists and *when* to
reach for it.

---

## Access modes

Every shortcut is exposed in two tables so it still works when tmux is nested
(local tmux ↔ tmux running over SSH on a workspace box).

| Mode | Key pattern | When to use |
|---|---|---|
| **Root (fast, local)** | `Ctrl+<key>` | Everyday use. Intercepted by the outermost tmux. |
| **Prefix (nested-safe)** | `Ctrl+b <key>` | Inside a nested tmux (e.g. SSH'd into workspace). Double-`Ctrl+b` forwards prefix one level deeper. |

A few bindings are prefix-only (`u`, `w`, `c`, `S`, `_`, `Escape`) because
their `Ctrl+<key>` equivalent conflicts with a readline/terminal binding
(typically `Ctrl+U` = clear-line-before-cursor).

---

## Claude-aware bindings

Three bindings resolve their path via
[`claude-pane-cwd`](../shell/bin/claude-pane-cwd) instead of the pane's raw
cwd. That helper walks the pane's process tree, finds descendant `claude`
processes, reads their cwd from `~/.claude/sessions/<pid>.json`, and:

- **0 Claude** in the tree → falls back to `$PWD` (pane's cwd).
- **1 Claude** → returns its cwd directly.
- **≥2 Claudes** (deduplicated by cwd) → fzf picker. Enter to select, Esc to cancel.

This matters because Claude's `--worktree` flag puts the session in
`.../<repo>/.claude/worktrees/<generated-name>/`, which the pane's own cwd
doesn't track.

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+t` / `t` | Open a shell popup in Claude's worktree | "I want to run `git diff` / `go test` / `rg` against what Claude just changed, without disturbing Claude." |
| `Ctrl+p` / `p` | Open the PR for Claude's branch in the browser | Mid-review: flip from terminal to the PR tab without mousing around. |
| `Ctrl+o` / `o` | Open Claude's branch on GitHub (tree view) | Share the branch link, eyeball the file layout on GitHub, or open on mobile. |

---

## Everyday bindings

### Sessions

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+Space` / `Space` | Toggle last session | Hop between `colibri` and `cloud-inventory` sessions in one keystroke. |
| `Ctrl+s` / `s` | fzf session switcher (typing a new name creates the session) | "Switch to the `dd-source` session if it exists, else spin one up." |
| `Ctrl+n` / `n` | New named session (prompt) | Deliberate session creation with a chosen name. |
| `Ctrl+r` / `r` | Rename current session | After `new-session` accidentally named it after cwd. |
| `Ctrl+k` / `k` | Kill sessions via fzf multi-select | Weekly cleanup of dead sessions. |
| `Ctrl+q` / `q` | Alias for `Ctrl+k` (Termius-friendly) | iPad Termius doesn't have a natural `Ctrl+K`. |

### Files & code

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+e` / `e` | File browser (fzf + bat preview) via `fb` | Navigate the pane's cwd without leaving tmux. |
| `Ctrl+f` / `f` | Alias for `Ctrl+e` (Termius-friendly) | `Ctrl+F` is easier to reach on iPad. |
| `Ctrl+g` / `g` | git log popup (fzf + `git show` preview) | Quick archaeology: "which commit touched this function?" |

### Links

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+l` | URL picker from pane scrollback (fzf → `open`) | Claude just printed a Datadog / GitHub URL in its output — grab it without mousing. |
| `M-k` | Clear screen + scrollback | Prep pane for a clean screenshot or demo. Bound also to `Cmd+K` via Ghostty. |

### Workspaces (prefix-only)

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+b w` | Enter / create `ws-luphaz` (main workspace over SSH) | First-thing-Monday: reconnect to the dev box. |
| `Ctrl+b c` | Enter / create `ws-luphaz-colibri` (colibri dev session) | Hop directly to the colibri shell on the workspace. |

### Maintenance (prefix-only)

| Binding | Action | Concrete use |
|---|---|---|
| `Ctrl+b u` | Pull `~/.dotfiles` then reload tmux | After `git push` from another machine — sync this one. |
| `Ctrl+b S` | Toggle synchronized panes | Run the same command in two panes at once (e.g. `tail -f` on two servers). |
| `Ctrl+b _` | Toggle silence-monitor (10s) on current pane | Long build / deploy — get a visual nudge when it finishes. |
| `Ctrl+b Escape` | Force-close any stuck popup | Escape hatch when a `display-popup` eats input. |

---

## Guiding principles (for future-me tempted to add more)

1. **Every binding should be reachable two ways** (root + prefix) unless there's a hard key conflict.
2. **Don't bind something you won't use weekly.** Muscle-memory budget is finite.
3. **Popups > new windows** for ephemeral things (picker, open-url, git log) — they disappear when done and don't pollute the window list.
4. **Claude-aware bindings beat cwd-aware bindings** when the action is about the *work* (PR, branch, diff), not the terminal location. The helper does the right thing by default.
5. **Termius aliases exist on purpose** (`Ctrl+f` → `fb`, `Ctrl+q` → kill) because some keys are physically painful on iOS.
