# Tmux Scripts

## session-picker.sh

Interactive worktree/session manager. Opens a fuzzy picker showing all git worktrees grouped by repository, with their tmux session status.

### Usage

Bound to `prefix + W` in tmux.

| Key | Action |
|-----|--------|
| `Enter` | Switch to session (if active) or open new session via `claude-worktree.sh` |
| `ctrl-r` | Refresh the list |
| `ctrl-x` | Kill the session for the selected worktree (with confirmation) |
| `Esc` / `ctrl-c` | Close without selecting |

### Display

```
    SESSION             BRANCH                              STATUS
  repo-name
  ▶ my-session          feat/my-feature                     active
    -                   main                                no session
  other-repo
    dev-session         fix/bug-123                         active
```

- `▶` marks the currently active tmux session
- SESSION column shows the tmux session name (or `-` if none)
- BRANCH column strips the username prefix (e.g. `user/feat` → `feat`)
- STATUS shows `active` (green) or `no session` (dim)

### Worktree Discovery

The picker collects worktrees from two sources:

1. **Active tmux sessions** — checks the path of pane `1.1` in each session, finds the git worktree root, and includes all worktrees for that repo
2. **Fixed roots** — scans `~/Workspace/worktrees/*/*` and `~/Workspace/conductor/workspaces/*/*` for directories containing a `.git` file (worktree marker)

Duplicate repos are deduplicated by their main worktree path.

### Session Matching

A worktree is matched to a tmux session by comparing the worktree path against the `pane_current_path` of pane `1.1` (window 1, pane 1) in each session. This pane is assumed to always be at the worktree root (e.g. lazygit).

### Opening Inactive Worktrees

Selecting a worktree with no active session delegates to `claude-worktree.sh`, which creates a new tmux session for that worktree.

## session-monitor.sh

Non-interactive version that prints a table of all active tmux sessions with their git branch and number of changed files relative to the main branch.

```
SESSION                   BRANCH                         CHANGES
-------                   ------                         -------
my-session                feat/my-feature                12
dev-session               fix/bug-123                    3
```
