---
name: init
description: One-time project setup for the taskflow email-notification gates. Writes scripts/notify-email.ps1, gitignores the secret, and appends the Development Notifications gate table to CLAUDE.md. Run once per project before using /taskflow:autocode or /taskflow:epct.
---

# init — wire up the taskflow notification gates in this project

Set up the email-gate plumbing in the CURRENT project. Be **idempotent**: if a piece already exists, leave it and report "already present". Never commit secrets.

## Steps

1. **Write `scripts/notify-email.ps1`** (create the `scripts/` folder if needed) with exactly this content:

```powershell
<#
.SYNOPSIS  Sends a notification email via the Brevo SMTP relay.
.DESCRIPTION
  Used by the taskflow EPCT gates. The SMTP key + recipient come from env vars, or from
  scripts\notify-email.local.ps1 (gitignored). A missing key prints an error and exits
  non-zero WITHOUT throwing, so it never aborts the surrounding workflow.
.EXAMPLE  powershell -File scripts/notify-email.ps1 -Subject "[TASK-1] Done" -Body "Shipped"
#>
param(
    [Parameter(Mandatory = $true)][string]$Subject,
    [Parameter(Mandatory = $true)][string]$Body,
    [string]$To     = $env:NOTIFY_EMAIL_TO,
    [string]$From   = $env:NOTIFY_EMAIL_FROM,
    [string]$Login  = $env:BREVO_SMTP_LOGIN,
    [string]$Server = "smtp-relay.brevo.com",
    [int]$Port = 587
)
$key = $env:BREVO_SMTP_KEY
if (-not $key -or -not $To -or -not $From -or -not $Login) {
    $localConfig = Join-Path $PSScriptRoot "notify-email.local.ps1"
    if (Test-Path $localConfig) {
        . $localConfig
        if (-not $key)   { $key   = $env:BREVO_SMTP_KEY }
        if (-not $To)    { $To    = $env:NOTIFY_EMAIL_TO }
        if (-not $From)  { $From  = $env:NOTIFY_EMAIL_FROM }
        if (-not $Login) { $Login = $env:BREVO_SMTP_LOGIN }
    }
}
if (-not $key -or -not $To -or -not $From -or -not $Login) {
    Write-Output "FAILED: missing email config. Create scripts/notify-email.local.ps1 (see .example) with your Brevo key + To/From/Login."
    exit 1
}
$client = $null; $msg = $null
try {
    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = $From; $msg.To.Add($To); $msg.Subject = $Subject; $msg.Body = $Body
    $client = New-Object System.Net.Mail.SmtpClient($Server, $Port)
    $client.EnableSsl = $true
    $client.Credentials = New-Object System.Net.NetworkCredential($Login, $key)
    $client.Send($msg)
    Write-Output "SUCCESS: email sent to $To"; exit 0
}
catch {
    $reason = $_.Exception.Message
    if ($_.Exception.InnerException) { $reason = "$reason | $($_.Exception.InnerException.Message)" }
    Write-Output "FAILED: $reason"; exit 1
}
finally { if ($msg) { $msg.Dispose() }; if ($client) { $client.Dispose() } }
```

2. **Write `scripts/notify-email.local.ps1.example`** with:

```powershell
# Copy to scripts/notify-email.local.ps1 (GITIGNORED — never commit) and fill in:
$env:BREVO_SMTP_KEY    = "<your-brevo-smtp-key>"
$env:BREVO_SMTP_LOGIN  = "<your-brevo-smtp-login>"   # e.g. 1234abc@smtp-brevo.com
$env:NOTIFY_EMAIL_TO   = "you@example.com"
$env:NOTIFY_EMAIL_FROM = "you@your-verified-domain.com"   # MUST be a Brevo-verified sender. A plain @gmail.com / @outlook.com From fails DMARC and gets bounced or spam-foldered.
```

3. **Gitignore the secret:** ensure `.gitignore` contains a line `scripts/notify-email.local.ps1` (append it if missing; create `.gitignore` if absent). This MUST be in place before you write the local file in Step 5.

4. **Append the gate table to `CLAUDE.md`** (create the file if it doesn't exist). Add this section verbatim unless it's already present:

```markdown
## MANDATORY: Development Notifications (email)

When running a multi-task pack with `/taskflow:epct`, work the tasks one at a time and **email the task owner at the gates below**. This is a stop-and-summon system. Send with:
`powershell -File scripts/notify-email.ps1 -Subject "<subject>" -Body "<body>"`
Email failures are non-fatal (log and continue), but a blocker still STOPS the task.

| # | When | Subject | Body |
|---|------|---------|------|
| 0 | About to start a task — **STOP**, wait for go-ahead | `[<TASK>] Starting — OK to proceed?` | task name + what it covers; paused awaiting confirmation |
| 1 | **Blocker / needs intervention** (any phase) — **STOP** | `[<TASK>] NEEDS YOUR INTERVENTION` | what stopped it, why, exactly what input is needed |
| 2 | Plan ready (awaiting `APPROVED`) — **STOP** | `[<TASK>] Plan ready — needs APPROVED` | summary + acceptance criteria + risks |
| 3 | QA done (awaiting `QA PASSED`) — **STOP** | `[<TASK>] QA <PASS/FAIL> — needs QA PASSED` | QA verdict + any failures |
| 4 | Task completed | `[<TASK>] Done` | what shipped + branch/commit |
| 5 | All work completed (whole module) | `[<MODULE>] All tasks complete` | per-task summary + outstanding risks |
```

5. **Offer to configure email now — but make it OPTIONAL.** Ask the user first: *"Configure email notifications now, or skip for later?"* (use AskUserQuestion with options like "Configure now" / "Skip for now").

   **If the user says NO / skip:**
   - Do NOT block. Email is a convenience layer, not a hard dependency — the EPCT/autocode gates still STOP and wait for the user in-chat; they just won't also send an email.
   - Leave the `.example` in place so the user can set it up later, and tell them: *"Email gates are skipped. The workflow stop-points still pause for your approval in chat. To enable email later, copy `scripts/notify-email.local.ps1.example` to `scripts/notify-email.local.ps1`, fill in your Brevo creds, and run the test — or just re-run `/taskflow:init`."*
   - Then finish init normally (the `.ps1`, `.example`, `.gitignore`, and CLAUDE.md gate table from Steps 1–4 are already done).

   **If the user says YES, collect the credentials and write the real local file yourself** — do NOT just point them at the `.example` (that is the #1 cause of setup failure: users edit `.example`, which the script never reads).
   - First confirm `.gitignore` contains `scripts/notify-email.local.ps1` (from Step 3). If it does not, STOP and fix that first — never write secrets to an un-ignored path.
   - If `scripts/notify-email.local.ps1` already exists, leave it and report "already present" — do not overwrite.
   - Otherwise, **use the AskUserQuestion tool (or ask directly)** to get all four values: `BREVO_SMTP_KEY`, `BREVO_SMTP_LOGIN` (e.g. `1234abc@smtp-brevo.com`), `NOTIFY_EMAIL_TO`, and `NOTIFY_EMAIL_FROM`.
   - **Validate `NOTIFY_EMAIL_FROM` is a Brevo-verified sender, not a bare `@gmail.com`/`@outlook.com`/`@yahoo.com` address.** Those free domains publish DMARC `p=reject`; Brevo cannot DKIM-sign for them, so mail to external recipients bounces or lands in spam (a same-provider test may still appear to "work"). If the user gives a free-mail From, warn them and recommend a verified domain sender before proceeding.
   - Write `scripts/notify-email.local.ps1` with exactly the four `$env:` lines (real values), prefixed by a comment: `# GITIGNORED — never commit.`
   - **Self-test:** run `powershell -File scripts/notify-email.ps1 -Subject "taskflow test" -Body "hello"` (use `pwsh` instead of `powershell` if only PowerShell 7+ is available) and confirm the output is `SUCCESS: email sent to …`. If it prints `FAILED:`, surface the reason and help fix it before finishing.

Report a short summary of what was created vs. already present, the email config status (configured / skipped), and the result of the self-test send if one was run.
