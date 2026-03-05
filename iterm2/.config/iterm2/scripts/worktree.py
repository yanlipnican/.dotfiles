#!/usr/bin/env python3
"""
Open a worktree in a new iTerm2 tab with lazygit on the left and an optional
command on the right split pane. Uses AppleScript via temp file for reliable IPC.
Usage: worktree.py <path> <name> [right_command]
"""
import sys
import subprocess
import tempfile
import os
import shlex

WORKTREE_PATH = sys.argv[1]
WORKTREE_NAME = sys.argv[2]
RIGHT_CMD = sys.argv[3] if len(sys.argv) > 3 else None


def as_str(s):
    """Wrap a Python string as an AppleScript string literal."""
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


left_cmd = f"cd {shlex.quote(WORKTREE_PATH)} && lazygit"

if RIGHT_CMD:
    script = f"""tell application "iTerm2"
    tell current window
        set newTab to (create tab with default profile)
        tell current session of newTab
            split vertically with default profile
        end tell
        tell first session of newTab
            write text {as_str(left_cmd)}
        end tell
        tell last session of newTab
            write text {as_str(f"cd {shlex.quote(WORKTREE_PATH)} && {RIGHT_CMD}")}
        end tell
    end tell
end tell"""
else:
    script = f"""tell application "iTerm2"
    tell current window
        set newTab to (create tab with default profile)
        tell current session of newTab
            write text {as_str(left_cmd)}
        end tell
    end tell
end tell"""

with tempfile.NamedTemporaryFile(mode='w', suffix='.applescript', delete=False) as f:
    f.write(script)
    tmpfile = f.name

try:
    subprocess.run(["osascript", tmpfile], check=True)
finally:
    os.unlink(tmpfile)
