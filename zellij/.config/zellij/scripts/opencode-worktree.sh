#!/bin/bash
# Open a tab with lazygit + opencode for a worktree.
# Resumes an opencode session by worktree name if one exists.
# If no session found, creates one by writing the session file directly.
# Supports: kitty, zellij
# Usage: opencode-worktree.sh <worktree-path> <worktree-name>

set -euo pipefail

WORKTREE_PATH="$(cd "${1:?Usage: opencode-worktree.sh <path> <name>}" && pwd -P)"
WORKTREE_NAME="${2:?Usage: opencode-worktree.sh <path> <name>}"

SESSION_DIR="$HOME/.local/share/opencode/storage/session"

# Find the projectID for this worktree by scanning existing session files
PROJECT_ID=""
for dir in "$SESSION_DIR"/*/; do
  for f in "$dir"*.json; do
    [ -f "$f" ] || continue
    d=$(jq -r '.directory // empty' "$f" 2>/dev/null)
    if [ "$d" = "$WORKTREE_PATH" ]; then
      PROJECT_ID=$(jq -r '.projectID // empty' "$f" 2>/dev/null)
      break 2
    fi
  done
done

# If no projectID found from existing sessions, get it from a temp server
if [ -z "$PROJECT_ID" ]; then
  TEMP_PORT=19876
  (cd "$WORKTREE_PATH" && /opt/homebrew/bin/opencode serve --port "$TEMP_PORT" >/dev/null 2>&1) &
  SERVE_PID=$!
  for i in $(seq 1 10); do
    sleep 1
    curl -sf "http://localhost:$TEMP_PORT/path" >/dev/null 2>&1 && break
  done
  PROJECT_ID=$(curl -sf "http://localhost:$TEMP_PORT/project/current" | jq -r '.id // empty')
  kill "$SERVE_PID" 2>/dev/null || true
  wait "$SERVE_PID" 2>/dev/null || true
fi

# Try to find an existing session by worktree name
SESSION_ID=""
if [ -n "$PROJECT_ID" ] && [ -d "$SESSION_DIR/$PROJECT_ID" ]; then
  SESSION_ID=$(jq -r --arg name "$WORKTREE_NAME" \
    'select(.title == $name) | .id' "$SESSION_DIR/$PROJECT_ID"/*.json 2>/dev/null \
    | head -1)
fi

# If no session found, create one by writing the file directly
if [ -z "$SESSION_ID" ] && [ -n "$PROJECT_ID" ]; then
  TIMESTAMP=$(date +%s)000
  SESSION_ID="ses_$(openssl rand -hex 6)$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 14)"
  SLUG_ADJ=("quick" "bright" "calm" "bold" "keen" "warm" "swift" "cool" "fair" "wise")
  SLUG_NOUN=("fox" "owl" "elk" "jay" "bee" "ram" "cod" "ant" "emu" "yak")
  SLUG="${SLUG_ADJ[$((RANDOM % 10))]}-${SLUG_NOUN[$((RANDOM % 10))]}"

  mkdir -p "$SESSION_DIR/$PROJECT_ID"
  cat > "$SESSION_DIR/$PROJECT_ID/$SESSION_ID.json" <<EOF
{
  "id": "$SESSION_ID",
  "slug": "$SLUG",
  "version": "1.1.50",
  "projectID": "$PROJECT_ID",
  "directory": "$WORKTREE_PATH",
  "title": "$WORKTREE_NAME",
  "time": {
    "created": $TIMESTAMP,
    "updated": $TIMESTAMP
  }
}
EOF
fi

OPENCODE_CMD="opencode --port"
if [ -n "$SESSION_ID" ]; then
  OPENCODE_CMD="opencode --port -s '$SESSION_ID'"
fi

ITERM_PYTHON=$(which python3)

# --- iTerm2 ---
if [ -n "${ITERM_SESSION_ID:-}" ] && [ -n "$ITERM_PYTHON" ]; then
  "$ITERM_PYTHON" ~/.config/iterm2/scripts/worktree.py "$WORKTREE_PATH" "$WORKTREE_NAME" "$OPENCODE_CMD"
  exit 0
fi

# --- Kitty ---
if [ -n "${KITTY_WINDOW_ID:-}" ]; then
  if kitty @ ls 2>/dev/null | jq -e --arg name "$WORKTREE_NAME" '.[].tabs[] | select(.title == $name)' > /dev/null 2>&1; then
    kitty @ focus-tab --match "title:^${WORKTREE_NAME}$"
    exit 0
  fi
  LG_ID=$(kitty @ launch --type=tab --tab-title "$WORKTREE_NAME" --cwd "$WORKTREE_PATH")
  kitty @ send-text --match "id:$LG_ID" "lazygit\r"
  kitty @ goto-layout splits
  OC_ID=$(kitty @ launch --type=window --location=vsplit --cwd "$WORKTREE_PATH")
  kitty @ send-text --match "id:$OC_ID" "${OPENCODE_CMD}\r"
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
  zellij action write-chars "$OPENCODE_CMD"
  zellij action write 10
  exit 0
fi

# Fallback
cd "$WORKTREE_PATH"
exec "${EDITOR:-nvim}" .
