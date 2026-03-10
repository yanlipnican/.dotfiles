#!/bin/bash
# Monitor tmux sessions: shows git status and claude status per session
# Usage: session-monitor.sh

SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

if [ -z "$SESSIONS" ]; then
  echo "No tmux sessions found."
  exit 0
fi

# Header
printf "%-25s %-30s %s\n" "SESSION" "BRANCH" "CHANGES"
printf "%-25s %-30s %s\n" "-------" "------" "-------"

while IFS= read -r session; do
  # Get working directory of first pane in session
  dir=$(tmux display-message -t "${session}:1.1" -p '#{pane_current_path}' 2>/dev/null)

  # Git info
  if git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="(detached)"
    main_dir=$(git -C "$dir" worktree list 2>/dev/null | awk 'NR==1{print $1}')
    main_branch=$(git -C "$main_dir" branch --show-current 2>/dev/null)
    changes=$(git -C "$dir" diff "$main_branch" --name-only 2>/dev/null | wc -l | tr -d ' ')
  else
    branch="-"
    changes="-"
  fi

  printf "%-25s %-30s %s\n" "$session" "$branch" "$changes"
done <<< "$SESSIONS"
