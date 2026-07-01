#!/usr/bin/env bash
# Cross-platform (macOS/Linux) notification email via Brevo SMTP, using curl.
# Usage: scripts/notify-email.sh "<subject>" "<body>"
# Reads config from env, or from scripts/notify-email.local.sh (gitignored) if present.
set -euo pipefail

SUBJECT="${1:?usage: notify-email.sh <subject> <body>}"
BODY="${2:?usage: notify-email.sh <subject> <body>}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$DIR/notify-email.local.sh" ] && . "$DIR/notify-email.local.sh"

: "${BREVO_SMTP_KEY:?missing BREVO_SMTP_KEY}"
: "${BREVO_SMTP_LOGIN:?missing BREVO_SMTP_LOGIN}"
: "${NOTIFY_EMAIL_TO:?missing NOTIFY_EMAIL_TO}"
: "${NOTIFY_EMAIL_FROM:?missing NOTIFY_EMAIL_FROM}"

curl -sS --url "smtp://smtp-relay.brevo.com:587" --ssl-reqd \
  --user "$BREVO_SMTP_LOGIN:$BREVO_SMTP_KEY" \
  --mail-from "$NOTIFY_EMAIL_FROM" \
  --mail-rcpt "$NOTIFY_EMAIL_TO" \
  --upload-file <(printf 'From: %s\nTo: %s\nSubject: %s\n\n%s\n' \
    "$NOTIFY_EMAIL_FROM" "$NOTIFY_EMAIL_TO" "$SUBJECT" "$BODY") \
  && echo "SUCCESS: email sent to $NOTIFY_EMAIL_TO" \
  || { echo "FAILED: curl smtp send failed"; exit 1; }
