#!/bin/bash
# Open a zellij tab with lazygit + shell for a worktree.
# Usage: worktree.sh <worktree-path> <worktree-name>

set -euo pipefail

WORKTREE_PATH="$(cd "${1:?Usage: worktree.sh <path> <name>}" && pwd -P)"
WORKTREE_NAME="${2:?Usage: worktree.sh <path> <name>}"

# If not inside zellij, just open editor in the worktree
if [ -z "${ZELLIJ:-}" ]; then
  cd "$WORKTREE_PATH"
  exec "${EDITOR:-nvim}" .
fi

# If tab already exists, just focus it
if zellij action query-tab-names 2>/dev/null | grep -qx "$WORKTREE_NAME"; then
  zellij action go-to-tab-name "$WORKTREE_NAME"
  exit 0
fi

# Create new tab
zellij action new-tab --cwd "$WORKTREE_PATH" --name "$WORKTREE_NAME"

# Start lazygit in the left pane
zellij action write-chars "lazygit"
zellij action write 10

# Open right pane with shell
zellij action new-pane --direction right --cwd "$WORKTREE_PATH"

zellij action write-chars "cd '$WORKTREE_PATH'"
zellij action write 10
