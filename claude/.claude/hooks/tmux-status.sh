#!/bin/bash
# Claude Code hook: sets CLAUDE_STATUS tmux env var on the matching session.
# Usage: tmux-status.sh <event>
# Events: PreToolUse | Stop | Notification

EVENT="$1"
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Stop/SessionEnd don't include cwd — fall back to the status file written by status_writer.py
if [ -z "$CWD" ]; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  if [ -n "$SESSION_ID" ]; then
    STATUS_FILE="$HOME/.clawed-code/sessions/${SESSION_ID}.json"
    [ -f "$STATUS_FILE" ] && CWD=$(jq -r '.cwd // empty' "$STATUS_FILE" 2>/dev/null)
  fi
fi

[ -z "$CWD" ] && exit 0

# For Notification, skip idle_prompt events
if [ "$EVENT" = "Notification" ]; then
  NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty' 2>/dev/null)
  [ "$NOTIF_TYPE" = "idle_prompt" ] && exit 0
fi

# Find the tmux session that has any pane at CWD
SESSION=$(tmux list-panes -a -F '#{session_name} #{pane_current_path}' 2>/dev/null | \
  while read -r s pdir; do
    [ "$pdir" = "$CWD" ] && echo "$s" && break
  done)

[ -z "$SESSION" ] && exit 0

case "$EVENT" in
  PreToolUse)   tmux set-environment -t "$SESSION" CLAUDE_STATUS working ;;
  Stop)         tmux set-environment -t "$SESSION" CLAUDE_STATUS idle ;;
  Notification) tmux set-environment -t "$SESSION" CLAUDE_STATUS needs_input ;;
esac
