#!/bin/bash
# Interactive worktree/session picker

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'

LABEL_IDLE=' worktrees — ctrl-r to refresh '
LABEL_LOADING=' worktrees — loading... '

generate() {
  local SESSIONS CURRENT_SESSION MAIN_DIRS CLAIMED_SESSIONS

  SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
  CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)

  MAIN_DIRS=""
  if [ -n "$SESSIONS" ]; then
    while IFS= read -r session; do
      dir=$(tmux display-message -t "${session}:1.1" -p '#{pane_current_path}' 2>/dev/null)
      if [ -n "$dir" ] && git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
        main_dir=$(git -C "$dir" worktree list 2>/dev/null | awk 'NR==1{print $1}')
        MAIN_DIRS="$MAIN_DIRS"$'\n'"$main_dir"
      fi
    done <<< "$SESSIONS"
  fi

  for root in "$HOME/Workspace/worktrees" "$HOME/Workspace/conductor/workspaces"; do
    for wt_path in "$root"/*/*; do
      [ -f "$wt_path/.git" ] || continue
      main_dir=$(git -C "$wt_path" worktree list 2>/dev/null | awk 'NR==1{print $1}')
      [ -n "$main_dir" ] && MAIN_DIRS="$MAIN_DIRS"$'\n'"$main_dir"
    done
  done

  MAIN_DIRS=$(echo "$MAIN_DIRS" | sort -u | grep -v '^$')
  CLAIMED_SESSIONS=""

  # Pass 1: collect all row data and compute max column widths
  declare -a R_TYPE R_PREFIX R_SESSION R_BRANCH R_STATUS_FMT R_WT_PATH R_WT_BRANCH R_SESSION_NAME R_REPO
  local max_session=7  # min = len("SESSION")
  local max_branch=6   # min = len("BRANCH")
  local idx=0

  while IFS= read -r main_dir; do
    [ -z "$main_dir" ] && continue
    local repo_name
    repo_name=$(basename "$main_dir")

    R_TYPE[$idx]="header"
    R_REPO[$idx]="$repo_name"
    R_WT_PATH[$idx]="HEADER"
    R_WT_BRANCH[$idx]="HEADER"
    R_SESSION_NAME[$idx]="HEADER"
    idx=$((idx + 1))

    while IFS= read -r wt_line; do
      local wt_path wt_branch branch_display session_name session_col status_fmt prefix
      wt_path=$(echo "$wt_line" | awk '{print $1}')
      wt_branch=$(echo "$wt_line" | awk '{print $3}' | tr -d '[]')
      [ -z "$wt_path" ] && continue

      branch_display=$(echo "$wt_branch" | sed 's|^[^/]*/||')

      session_name=""
      if [ -n "$SESSIONS" ]; then
        while IFS= read -r s; do
          local s_dir
          s_dir=$(tmux display-message -t "${s}:1.1" -p '#{pane_current_path}' 2>/dev/null)
          if [ "$s_dir" = "$wt_path" ] && tmux show-environment -t "$s" CLAUDE_WORKTREE 2>/dev/null | grep -q '^CLAUDE_WORKTREE='; then
            session_name="$s"
            break
          fi
        done <<< "$SESSIONS"
      fi

      if [ -n "$session_name" ]; then
        status_fmt="${GREEN}active${RESET}"
        session_col="$session_name"
        CLAIMED_SESSIONS="$CLAIMED_SESSIONS"$'\n'"$session_name"
      else
        status_fmt="${DIM}no session${RESET}"
        session_col="-"
        session_name="-"
      fi

      [ "$session_name" = "$CURRENT_SESSION" ] && prefix="  ▶ " || prefix="    "

      local len
      len=${#session_col}
      [ $len -gt $max_session ] && max_session=$len
      len=${#branch_display}
      [ $len -gt $max_branch ] && max_branch=$len

      R_TYPE[$idx]="row"
      R_PREFIX[$idx]="$prefix"
      R_SESSION[$idx]="$session_col"
      R_BRANCH[$idx]="$branch_display"
      R_STATUS_FMT[$idx]="$status_fmt"
      R_WT_PATH[$idx]="$wt_path"
      R_WT_BRANCH[$idx]="$wt_branch"
      R_SESSION_NAME[$idx]="$session_name"
      idx=$((idx + 1))
    done <<< "$(git -C "$main_dir" worktree list)"
  done <<< "$MAIN_DIRS"

  # Append sessions not matched to any worktree
  if [ -n "$SESSIONS" ]; then
    local has_other=0
    while IFS= read -r session; do
      [ -z "$session" ] && continue
      echo "$CLAIMED_SESSIONS" | grep -qxF "$session" && continue

      if [ $has_other -eq 0 ]; then
        R_TYPE[$idx]="header"; R_REPO[$idx]="other"
        R_WT_PATH[$idx]="HEADER"; R_WT_BRANCH[$idx]="HEADER"; R_SESSION_NAME[$idx]="HEADER"
        idx=$((idx + 1))
        has_other=1
      fi

      local s_dir s_display
      s_dir=$(tmux display-message -t "${session}:1.1" -p '#{pane_current_path}' 2>/dev/null)
      s_display="${s_dir/#$HOME/\~}"

      local prefix
      [ "$session" = "$CURRENT_SESSION" ] && prefix="  ▶ " || prefix="    "

      local is_worktree_session status_fmt
      is_worktree_session=$(tmux show-environment -t "$session" CLAUDE_WORKTREE 2>/dev/null | grep -c '^CLAUDE_WORKTREE=')
      if [ "$is_worktree_session" -gt 0 ]; then
        status_fmt="${CYAN}worktree${RESET}"
      else
        status_fmt="${GREEN}active${RESET}"
      fi

      local len
      len=${#session}; [ $len -gt $max_session ] && max_session=$len
      len=${#s_display}; [ $len -gt $max_branch ] && max_branch=$len

      R_TYPE[$idx]="row"; R_PREFIX[$idx]="$prefix"
      R_SESSION[$idx]="$session"; R_BRANCH[$idx]="$s_display"
      R_STATUS_FMT[$idx]="$status_fmt"
      R_WT_PATH[$idx]="$s_dir"; R_WT_BRANCH[$idx]="-"; R_SESSION_NAME[$idx]="$session"
      idx=$((idx + 1))
    done <<< "$SESSIONS"
  fi

  [ $idx -eq 0 ] && return

  # Pass 2: output header line (for --header-lines=1), then rows
  local h_session h_branch
  h_session=$(printf "%-${max_session}s" "SESSION")
  h_branch=$(printf "%-${max_branch}s" "BRANCH")
  printf "    ${DIM}%s  %s  %s${RESET}\tHEADER\tHEADER\tHEADER\n" "$h_session" "$h_branch" "STATUS"

  local lines=""
  for ((i = 0; i < idx; i++)); do
    if [ "${R_TYPE[$i]}" = "header" ]; then
      lines+="${BOLD}${CYAN}  ${R_REPO[$i]}${RESET}"$'\t'HEADER$'\t'HEADER$'\t'HEADER$'\n'
    else
      local col_session col_branch
      col_session=$(printf "%-${max_session}s" "${R_SESSION[$i]}")
      col_branch=$(printf "%-${max_branch}s" "${R_BRANCH[$i]}")
      lines+="${R_PREFIX[$i]}${col_session}  ${col_branch}  ${R_STATUS_FMT[$i]}"$'\t'"${R_WT_PATH[$i]}"$'\t'"${R_WT_BRANCH[$i]}"$'\t'"${R_SESSION_NAME[$i]}"$'\n'
    fi
  done

  printf '%s' "$lines"
}

if [ "$1" = "--generate" ]; then
  generate
  exit 0
fi

if [ "$1" = "--create" ]; then
  wt_path="$2"
  [ "$wt_path" = "HEADER" ] && exit 0

  main_dir=$(git -C "$wt_path" worktree list 2>/dev/null | awk 'NR==1{print $1}')
  repo_name=$(basename "$main_dir")

  worktree_root="$HOME/Workspace/worktrees"
  for root in "$HOME/Workspace/worktrees" "$HOME/Workspace/conductor/workspaces"; do
    [[ "$wt_path" == "$root"/* ]] && worktree_root="$root" && break
  done

  # Step 1: pick base branch (default: master or main, whichever exists)
  if git -C "$main_dir" rev-parse --verify master &>/dev/null; then
    default_base="master"
  elif git -C "$main_dir" rev-parse --verify main &>/dev/null; then
    default_base="main"
  else
    default_base=""
  fi
  base_branch=$(git -C "$main_dir" branch -a --format '%(refname:short)' \
    | sed 's|^origin/||' | sort -u \
    | fzf --prompt "Base branch: " --height 10 --reverse --border \
          --border-label " base branch " --query "$default_base" --select-1)
  [ -z "$base_branch" ] && exit 0

  # Step 2: enter new branch name, re-prompt if already exists
  while true; do
    read -rp "New branch name: " branch </dev/tty
    [ -z "$branch" ] && exit 0
    if git -C "$main_dir" rev-parse --verify "$branch" &>/dev/null; then
      echo "Branch '$branch' already exists, choose a different name."
    else
      break
    fi
  done

  wt_new="$worktree_root/$repo_name/$branch"
  mkdir -p "$(dirname "$wt_new")"

  git -C "$main_dir" worktree add "$wt_new" -b "$branch" "$base_branch"

  ~/.config/tmux/scripts/claude-worktree.sh "$wt_new" "$branch"
  exit 0
fi

if [ "$1" = "--delete" ]; then
  wt_path="$2"
  session_name="$3"
  [ "$wt_path" = "HEADER" ] && exit 0

  if [ "$session_name" != "-" ]; then
    confirm=$(printf 'no\nyes' | fzf --prompt "Kill session $session_name? " --height 4 --reverse)
    [ "$confirm" = "yes" ] && tmux kill-session -t "$session_name"
  else
    branch_name=$(basename "$wt_path")
    confirm=$(printf 'no\nyes' | fzf --prompt "Delete worktree $branch_name? " --height 4 --reverse)
    if [ "$confirm" = "yes" ]; then
      git -C "$wt_path" worktree remove "$wt_path" --force 2>/dev/null || rm -rf "$wt_path"
    fi
  fi
  exit 0
fi

selected=$(fzf-tmux -p 90%,70% \
  --ansi \
  --delimiter $'\t' \
  --with-nth 1 \
  --layout=reverse \
  --header-lines=1 \
  --border-label "$LABEL_LOADING" \
  --prompt '  ' \
  --no-sort \
  --bind "start:reload($0 --generate)" \
  --bind "load:change-border-label($LABEL_IDLE)" \
  --bind "ctrl-r:change-border-label($LABEL_LOADING)+reload($0 --generate)" \
  --bind "ctrl-n:execute($0 --create {2})+abort" \
  --bind "ctrl-x:execute($0 --delete {2} {4})+reload($0 --generate)")

[ -z "$selected" ] && exit 0

wt_path=$(echo "$selected" | cut -f2)
wt_branch=$(echo "$selected" | cut -f3)
session_name=$(echo "$selected" | cut -f4)

[ "$wt_path" = "HEADER" ] && exit 0

if [ "$session_name" = "-" ]; then
  ~/.config/tmux/scripts/claude-worktree.sh "$wt_path" "$wt_branch"
else
  tmux switch-client -t "$session_name"
fi
