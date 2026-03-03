---
name: himalaya
description: "CLI to manage emails via IMAP/SMTP. Use `himalaya` to list, read, write, reply, forward, search, and organize emails from the terminal. Supports multiple accounts and message composition with MML (MIME Meta Language)."
homepage: https://github.com/pimalaya/himalaya
metadata:
  {
    "openclaw":
      {
        "emoji": "📧",
        "requires": { "bins": ["himalaya"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "himalaya",
              "bins": ["himalaya"],
              "label": "Install Himalaya (brew)",
            },
          ],
      },
  }
---

# Himalaya Email CLI

Himalaya is a CLI email client that lets you manage emails from the terminal using IMAP, SMTP, Notmuch, or Sendmail backends.

## References

- `references/configuration.md` (config file setup + IMAP/SMTP authentication)
- `references/message-composition.md` (MML syntax for composing emails)

## Prerequisites

1. Himalaya CLI installed (`himalaya --version` to verify)
2. A configuration file — check BOTH locations: `~/.config/himalaya/config.toml` AND `~/Library/Application Support/himalaya/config.toml` (macOS). **Always read the existing config before modifying it.**
3. IMAP/SMTP credentials configured (password stored securely)

## Configuration Setup

**IMPORTANT:** Always check if a config file already exists before creating one. Read it first to understand the current setup.

Run the interactive wizard to set up an account:

```bash
himalaya account configure
```

Or create the config manually:

```toml
[accounts.personal]
email = "you@example.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show email/imap"  # or use keyring

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "you@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show email/smtp"
```

### Password Storage Options

The `backend.auth` field supports these types (check `himalaya --help` for available cargo features):

- `backend.auth.cmd = "command"` — run a command that outputs the password (most reliable, always available)
- `backend.auth.raw = "password"` — plaintext password (not recommended)
- `backend.auth.keyring = "service-name"` — system keyring (requires `keyring` cargo feature, may not be compiled in)

**On macOS**, the most reliable approach is using `cmd` with the `security` command:

```toml
backend.auth.cmd = "security find-generic-password -a 'user@example.com' -s 'service-name' -w"
```

Store the password first with:
```bash
security add-generic-password -a "user@example.com" -s "service-name" -w "YOUR_PASSWORD"
```

### Gmail Configuration

Gmail requires an App Password (generate at https://myaccount.google.com/apppasswords with 2FA enabled). Use port 465 with TLS for SMTP (not 587 with STARTTLS).

```toml
[accounts.gmail]
email = "you@gmail.com"
display-name = "Your Name"
default = true

folder.aliases.inbox = "INBOX"
folder.aliases.sent = "[Gmail]/Sent Mail"
folder.aliases.drafts = "[Gmail]/Drafts"
folder.aliases.trash = "[Gmail]/Trash"

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@gmail.com"
backend.auth.type = "password"
backend.auth.cmd = "security find-generic-password -a 'you@gmail.com' -s 'gmail-app-password' -w"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "you@gmail.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "security find-generic-password -a 'you@gmail.com' -s 'gmail-app-password' -w"
```

**Gmail IMAP quirk:** Gmail category tabs (Promotions, Social, Updates, Forums) do NOT map to IMAP folders. They all live in INBOX. Only `[Gmail]/Sent Mail`, `[Gmail]/Drafts`, `[Gmail]/Trash`, `[Gmail]/Spam`, `[Gmail]/All Mail`, `[Gmail]/Starred`, `[Gmail]/Important` are separate IMAP folders.

## Common Operations

### List Folders

```bash
himalaya folder list
```

### List Emails

List emails in INBOX (default):

```bash
himalaya envelope list
```

List emails in a specific folder:

```bash
himalaya envelope list --folder "[Gmail]/Sent Mail"
```

List with pagination:

```bash
himalaya envelope list --page 1 --page-size 20
```

**When processing many emails, always use `--page-size 250` (max) and iterate pages to get everything. Don't assume the default page size covers all emails.**

### Search Emails

```bash
himalaya envelope list from john@example.com subject meeting
```

### Read an Email

Read email by ID (shows plain text):

```bash
himalaya message read 42
```

**Tip:** When reading many emails, batch them in parallel or in a loop. Don't read them one at a time interactively. Pipe through `grep -v '^\[2m'` to strip ANSI warn/debug lines from output.

### Reply to an Email

Interactive reply (opens $EDITOR):

```bash
himalaya message reply 42
```

Reply-all:

```bash
himalaya message reply 42 --all
```

### Forward an Email

```bash
himalaya message forward 42
```

### Write a New Email

Interactive compose (opens $EDITOR):

```bash
himalaya message write
```

Send directly using template:

```bash
cat << 'EOF' | himalaya template send
From: you@example.com
To: recipient@example.com
Subject: Test Message

Hello from Himalaya!
EOF
```

### Move/Copy Emails

Move to folder:

```bash
himalaya message move 42 "Archive"
```

Copy to folder:

```bash
himalaya message copy 42 "Important"
```

### Delete an Email

```bash
himalaya message delete 42
```

### Manage Flags

The flag syntax uses positional args — IDs and flag names together, NOT `--flag`:

```bash
# Add seen flag to one email
himalaya flag add 42 seen

# Add seen flag to multiple emails (batch)
himalaya flag add 42 43 44 45 seen

# Remove seen flag
himalaya flag remove 42 seen
```

**Batch flag operations:** You can pass many IDs at once but there's a limit. Batch in groups of ~50 IDs per call. Use `awk` to extract IDs, not `xargs` (which can introduce whitespace issues):

```bash
# Example: mark all unread as read
himalaya envelope list --page-size 250 | grep ' \*' | awk -F'|' '{gsub(/ /,"",$2); print $2}' > /tmp/ids.txt
IDS=$(awk 'NR>=1 && NR<=50' /tmp/ids.txt | tr '\n' ' ')
eval "himalaya flag add $IDS seen"
```

## Multiple Accounts

List accounts:

```bash
himalaya account list
```

Use a specific account:

```bash
himalaya --account work envelope list
```

## Attachments

Save attachments from a message:

```bash
himalaya attachment download 42
```

Save to specific directory:

```bash
himalaya attachment download 42 --dir ~/Downloads
```

## Output Formats

Most commands support `--output` for structured output:

```bash
himalaya envelope list --output json
himalaya envelope list --output plain
```

## Debugging

Enable debug logging:

```bash
himalaya --debug envelope list
```

Full trace with backtrace:

```bash
himalaya --trace envelope list
```

## How to Process an Inbox

When the user asks you to read/process/triage their emails, follow this workflow:

### 1. Fetch ALL emails first

Never assume the default page size is enough. Always paginate to get everything:

```bash
for page in 1 2 3 4 5; do
  himalaya envelope list --page-size 250 --page $page 2>&1
done
```

Keep paginating until a page returns 0 results. Count the total so you can tell the user how many there are.

### 2. Filter noise by sender/subject

Use `grep -viE` to remove obvious noise (app notifications, deployment alerts, etc.). Common noise senders:
- Sentry, GitHub, GitLab, Bitbucket (deployment/CI notifications)
- Figma, Notion, Linear, Jira, Asana, Confluence (app notifications)
- Slack, Teams (message notifications)
- LinkedIn, Docker, marketing emails
- 15Five, Lattice, etc. (HR tool reminders)

But **ask the user** what they consider noise — don't assume.

### 3. Actually READ the remaining emails

**Do not summarize emails from subject lines alone.** You must read the content of every email you report on. If you didn't read it, don't summarize it — be honest about what you skipped.

Read emails in batch using a loop, not one by one:

```bash
for id in 101 102 103 104; do
  echo "===== ID: $id ====="
  himalaya message read $id 2>&1 | grep -v '^\[2m' | head -40
  echo
done
```

### 4. Be honest in your summary

- Clearly state how many total emails there were
- Clearly state how many you actually read vs. filtered out
- Don't present inferences from subject lines as if you read the content
- If you're unsure about an email, say so and offer to read it

### 5. Batch operations at the end

If the user wants to mark as read, archive, etc., do it in batches of ~50 IDs (see Manage Flags section above).

## Tips

- Use `himalaya --help` or `himalaya <command> --help` for detailed usage.
- Message IDs are relative to the current folder; re-list after folder changes.
- For composing rich emails with attachments, use MML syntax (see `references/message-composition.md`).
- Store passwords securely using `cmd` with `security` (macOS) or `pass` (Linux). The `keyring` option requires the keyring cargo feature which may not be compiled in.
- The envelope list `*` flag in the FLAGS column indicates unread (unseen) messages.
- When processing large inboxes, always paginate with `--page-size 250` and iterate all pages. Don't assume the default page size is enough.
- Gmail's category tabs are not IMAP folders — all categorized mail is in INBOX via IMAP.
