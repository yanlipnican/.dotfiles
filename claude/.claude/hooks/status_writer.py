#!/usr/bin/env python3
"""
status_writer.py
Clawed Code Hook Script (Multi-Instance Version)

Writes Claude Code status updates to per-session JSON files for multi-cat monitoring.
This script is called by Claude Code hooks at various lifecycle events.

Usage:
    python3 status_writer.py <event_type>

Event types:
    - PreToolUse: Before any tool execution
    - PostToolUse: After tool completion
    - Notification: When Claude needs user input (filters out idle_prompt)
    - Stop: When the main agent completes (writes "completed" status)
    - SessionStart: When a new session starts
    - SessionEnd: When a session ends (DELETES session file)
"""

import json
import sys
import os
import time
from datetime import datetime


# Sessions directory for multi-instance support
SESSIONS_DIR = os.path.expanduser("~/.clawed-code/sessions")

# Legacy single-file path (for backwards compatibility)
LEGACY_STATUS_FILE = os.path.expanduser("~/.clawed-code/status.json")

# Initialization phase threshold (seconds)
INIT_PHASE_SECONDS = 15


def is_initialization_phase(session_id):
    """
    Check if session is still in initialization phase (before user interaction).

    Claude Code 2.1+ runs automatic file discovery (Glob, Bash) at startup.
    During this phase, PreToolUse should be ignored so the app stays at "idle"
    until the user actually sends a message.
    """
    file_path = get_session_file_path(session_id)
    if os.path.exists(file_path):
        # Use st_birthtime on macOS for actual file creation time
        # (getctime returns metadata change time on Unix)
        stat_info = os.stat(file_path)
        created = getattr(stat_info, 'st_birthtime', stat_info.st_mtime)
        age = time.time() - created
        return age < INIT_PHASE_SECONDS
    return False


def get_session_file_path(session_id):
    """Get path to session-specific status file."""
    return os.path.join(SESSIONS_DIR, f"{session_id}.json")


def ensure_directories():
    """Ensure all required directories exist."""
    os.makedirs(SESSIONS_DIR, exist_ok=True)


def extract_title_from_transcript(transcript_path, max_length=100):
    """
    Extract the first user message from transcript as the session title.

    Args:
        transcript_path: Path to the JSONL transcript file
        max_length: Maximum length of the returned title

    Returns:
        The first user prompt, truncated to max_length, or "New Session" if not found
    """
    if not transcript_path or not os.path.exists(transcript_path):
        return "New Session"

    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    msg = json.loads(line.strip())
                    content = None

                    # Claude Code transcript format: {"type":"user","message":{"role":"user","content":[...]}}
                    if msg.get('type') == 'user' and 'message' in msg:
                        nested_msg = msg.get('message', {})
                        if nested_msg.get('role') == 'user':
                            content = nested_msg.get('content', '')

                    # Fallback: direct role check (other formats)
                    elif msg.get('role') == 'user':
                        content = msg.get('content', '')

                    if content is not None:
                        # Handle content that might be a list (multimodal)
                        if isinstance(content, list):
                            # Find text content
                            for item in content:
                                if isinstance(item, dict) and item.get('type') == 'text':
                                    content = item.get('text', '')
                                    break
                                elif isinstance(item, str):
                                    content = item
                                    break
                            else:
                                content = ''

                        if content:
                            # Clean and truncate
                            content = content.strip()
                            if len(content) > max_length:
                                return content[:max_length-3] + "..."
                            return content if content else "New Session"
                except json.JSONDecodeError:
                    continue
    except Exception as e:
        print(f"⚠️ Could not extract title: {e}", file=sys.stderr)

    return "New Session"


def write_session_status(session_id, status_type, data):
    """
    Write status update to session-specific file.

    Args:
        session_id: Unique session identifier
        status_type: One of 'idle', 'working', 'needs_input', 'completed'
        data: Dict containing cwd, transcript_path, etc.
    """
    ensure_directories()
    file_path = get_session_file_path(session_id)

    # Extract title from transcript (or use cached title from existing file)
    title = "New Session"
    transcript_path = data.get("transcript_path")

    # Try to read existing title first (avoid re-reading transcript every time)
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r') as f:
                existing = json.load(f)
                title = existing.get("title", "New Session")
        except:
            pass

    # On SessionStart or if title is still default, extract from transcript
    if title == "New Session" and transcript_path:
        title = extract_title_from_transcript(transcript_path)

    # Build session data
    session_data = {
        "session_id": session_id,
        "status": status_type,
        "title": title,
        "cwd": data.get("cwd", ""),
        "transcript_path": transcript_path,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

    # Write atomically to file
    try:
        with open(file_path, 'w') as f:
            json.dump(session_data, f, indent=2)
        print(f"✅ Session status updated: {session_id} -> {status_type}", file=sys.stderr)
    except Exception as e:
        print(f"❌ Error writing session status: {e}", file=sys.stderr)


def delete_session_file(session_id):
    """Delete the session file (for Stop/SessionEnd events)."""
    file_path = get_session_file_path(session_id)

    if os.path.exists(file_path):
        try:
            os.remove(file_path)
            print(f"🗑️ Session file deleted: {session_id}", file=sys.stderr)
        except Exception as e:
            print(f"❌ Error deleting session file: {e}", file=sys.stderr)


def write_legacy_status(status_type, data):
    """Write to legacy single-file for backwards compatibility."""
    ensure_directories()

    status = {
        "status": status_type,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "tool": data.get("tool_name"),
        "session": data.get("session_id")
    }

    try:
        # Ensure parent directory exists
        os.makedirs(os.path.dirname(LEGACY_STATUS_FILE), exist_ok=True)
        with open(LEGACY_STATUS_FILE, 'w') as f:
            json.dump(status, f, indent=2)
    except Exception as e:
        print(f"⚠️ Legacy status write failed: {e}", file=sys.stderr)


def main():
    """Main entry point for hook script."""
    # Get event type from command line
    if len(sys.argv) < 2:
        print("Usage: status_writer.py <event_type>", file=sys.stderr)
        sys.exit(1)

    event_type = sys.argv[1]

    # Read JSON data from stdin (if available)
    data = {}
    if not sys.stdin.isatty():
        try:
            data = json.load(sys.stdin)
        except json.JSONDecodeError:
            print("⚠️ Could not parse JSON from stdin", file=sys.stderr)

    # Filter out idle_prompt notifications (false "needs input" after 60s idle)
    if event_type == 'Notification':
        # Field is "notification_type" in the payload, not just "type"
        notification_type = data.get('notification_type', '')
        if notification_type == 'idle_prompt':
            print("⏭️ Skipping idle_prompt notification (not a real input request)", file=sys.stderr)
            return

    # Map event types to status
    status_map = {
        'PreToolUse': 'working',
        'PostToolUse': 'working',
        'Notification': 'needs_input',
        'Stop': 'completed',
        'SessionStart': 'idle',
        'SessionEnd': 'idle'
    }

    # Get session ID from data (needed for initialization check)
    session_id = data.get("session_id")

    # Get mapped status
    status_type = status_map.get(event_type, 'unknown')

    # Skip PreToolUse during initialization phase - keeps status at "idle"
    # Claude Code 2.1+ runs automatic Glob/Bash at startup before user interaction
    # These only trigger PreToolUse (not PostToolUse), so we ignore them entirely
    if event_type == 'PreToolUse' and session_id and is_initialization_phase(session_id):
        print(f"🚀 Initialization phase: ignoring PreToolUse (staying idle)", file=sys.stderr)
        return  # Exit early, don't write "working" status

    if status_type == 'unknown':
        print(f"⚠️ Unknown event type: {event_type}", file=sys.stderr)
        return

    if session_id:
        # Multi-instance mode: write to per-session file
        if event_type == 'SessionEnd':
            # Only delete on explicit session end (not completion)
            delete_session_file(session_id)
        else:
            # Write status (including "completed" for Stop event)
            write_session_status(session_id, status_type, data)

        # Also write legacy file for backwards compatibility
        write_legacy_status(status_type, data)
    else:
        # No session ID: fallback to legacy single-file mode
        print("⚠️ No session_id provided, using legacy mode", file=sys.stderr)
        write_legacy_status(status_type, data)


if __name__ == '__main__':
    main()
