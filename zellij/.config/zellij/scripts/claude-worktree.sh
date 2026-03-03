#!/bin/bash
# Open a tab with lazygit + claude for a worktree.
# Supports: kitty, zellij
# Usage: claude-worktree.sh <worktree-path> <worktree-name>

set -euo pipefail

WORKTREE_PATH="$(cd "${1:?Usage: claude-worktree.sh <path> <name>}" && pwd -P)"
WORKTREE_NAME="${2:?Usage: claude-worktree.sh <path> <name>}"

# --- Kitty ---
if [ -n "${KITTY_WINDOW_ID:-}" ]; then
  if kitty @ ls 2>/dev/null | jq -e --arg name "$WORKTREE_NAME" '.[].tabs[] | select(.title == $name)' > /dev/null 2>&1; then
    kitty @ focus-tab --match "title:^${WORKTREE_NAME}$"
    exit 0
  fi
  LG_ID=$(kitty @ launch --type=tab --tab-title "$WORKTREE_NAME" --cwd "$WORKTREE_PATH")
  kitty @ send-text --match "id:$LG_ID" "lazygit\r"
  kitty @ goto-layout splits
  CLAUDE_ID=$(kitty @ launch --type=window --location=vsplit --cwd "$WORKTREE_PATH")
  kitty @ send-text --match "id:$CLAUDE_ID" "claude --resume --ide\r"
  exit 0
fi

# --- Zellij ---
if [ -n "${ZELLIJ:-}" ]; then
  if zellij action query-tab-names 2>/dev/null | grep -qx "$WORKTREE_NAME"; then
    zellij action go-to-tab-name "$WORKTREE_NAME"
    exit 0
  fi
  zellij action new-tab --cwd "$WORKTREE_PATH" --name "$WORKTREE_NAME"
  zellij action write-chars "lazygit"
  zellij action write 10
  zellij action new-pane --direction right --cwd "$WORKTREE_PATH"
  zellij action write-chars "cd '$WORKTREE_PATH'"
  zellij action write 10
  sleep 0.5
  zellij action write-chars "claude --resume --ide"
  zellij action write 10
  exit 0
fi

# Fallback
cd "$WORKTREE_PATH"
exec "${EDITOR:-nvim}" .
