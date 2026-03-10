#!/bin/bash
# Open a tmux window with lazygit + shell for a worktree.
# Usage: worktree.sh <worktree-path> <worktree-name>

WORKTREE_PATH="$(cd "${1:?Usage: worktree.sh <path> <name>}" && pwd -P)"
WORKTREE_NAME="${2:?Usage: worktree.sh <path> <name>}"

tmux start-server
sleep 0.2

if ! tmux has-session -t "=$WORKTREE_NAME" 2>/dev/null; then
  tmux new-session -d -s "$WORKTREE_NAME" -c "$WORKTREE_PATH"
  tmux send-keys -t "=$WORKTREE_NAME:0.0" "lazygit" Enter
  tmux split-window -h -t "=$WORKTREE_NAME:0.0" -c "$WORKTREE_PATH"
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$WORKTREE_NAME"
else
  tmux attach-session -t "=$WORKTREE_NAME"
fi
