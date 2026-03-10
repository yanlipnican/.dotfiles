#!/bin/bash
# Open a tmux session with lazygit + claude for a worktree.
# Usage: claude-worktree.sh <worktree-path> <worktree-name>

WORKTREE_PATH="$(cd "${1:?Usage: claude-worktree.sh <path> <name>}" && pwd -P)"
WORKTREE_NAME="${2:?Usage: claude-worktree.sh <path> <name>}"

tmux start-server
sleep 0.2

if ! tmux has-session -t "=$WORKTREE_NAME" 2>/dev/null; then
  # Create session and capture the first pane ID
  PANE_LEFT=$(tmux new-session -d -s "$WORKTREE_NAME" -c "$WORKTREE_PATH" -x 220 -y 50 -P -F '#{pane_id}')
  tmux set-environment -t "$WORKTREE_NAME" CLAUDE_WORKTREE 1

  # Split right 60% for claude, capture pane ID
  PANE_CLAUDE=$(tmux split-window -h -l "60%" -t "$PANE_LEFT" -c "$WORKTREE_PATH" -P -F '#{pane_id}')

  # Split claude pane bottom 30% for shell, capture pane ID
  tmux split-window -v -l "30%" -t "$PANE_CLAUDE" -c "$WORKTREE_PATH"

  # Send commands using captured pane IDs
  tmux send-keys -t "$PANE_LEFT" "lazygit" Enter
  tmux send-keys -t "$PANE_CLAUDE" "claude --resume --ide" Enter

  # Focus claude
  tmux select-pane -t "$PANE_CLAUDE"
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$WORKTREE_NAME"
else
  tmux attach-session -t "=$WORKTREE_NAME"
fi
