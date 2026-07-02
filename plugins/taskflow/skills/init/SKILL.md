---
name: init
description: One-time, guided project setup for the taskflow email notifications. Writes scripts/notify-email.ps1, gitignores the secret, appends the Development Notifications table to CLAUDE.md, and (optionally) configures + tests your Brevo email credentials. Run once per project before using /taskflow:autocode or /taskflow:epct-rn.
---

# init — guided setup for taskflow email notifications

Set up the email-notification plumbing in the CURRENT project. Be **idempotent** (if a piece already exists, leave it and say "already present") and **never commit secrets**.

## How to communicate (IMPORTANT — this is the whole point of this skill)

The old flow confused users: it created files silently, then asked for credentials, then created more files, with no explanation. **Fix that by narrating every step.** After each action, tell the user in plain language:

- **What just happened** — e.g. "Created `scripts/notify-email.ps1`."
- **Why** — e.g. "This is the script that actually sends the emails."
- **What's next** — e.g. "Next I'll make sure your secret key can never be committed."

Group the work into three clearly-announced parts (A, B, C below). **Announce each part before starting it**, and end with a **"You're all set — here's what to do next"** summary. Keep it friendly and concrete; no silent file creation.

---

## Part A — Create the plumbing (always runs, no secrets involved)

Tell the user: *"First I'll create the notification plumbing. These files contain NO secrets and are safe to commit — they're the same for everyone on your team."*

### A1. Write `scripts/notify-email.ps1` (create `scripts/` if needed)

Say what it is: *"This is the sender — the workflow calls it to email you. No secrets live here."* Content:

```powershell
<#
.SYNOPSIS  Sends a notification email via the Brevo SMTP relay.
.DESCRIPTION
  Used by the taskflow EPCT notifications. The SMTP key + recipient come from env vars, or from
  scripts\notify-email.local.ps1 (gitignored). A missing key prints an error and exits
  non-zero WITHOUT throwing, so it never aborts the surrounding workflow.
.EXAMPLE  powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "[TASK-1] Done" -Body "Shipped"
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

### A2. Write `scripts/notify-email.local.ps1.example`

Say what it is: *"This is a template showing which values you'll need. It's a placeholder only — you never edit this one; in Part B I'll create the real (private) file for you."* Content:

```powershell
# Copy to scripts/notify-email.local.ps1 (GITIGNORED — never commit) and fill in:
$env:BREVO_SMTP_KEY    = "<your-brevo-smtp-key>"
$env:BREVO_SMTP_LOGIN  = "<your-brevo-smtp-login>"   # e.g. 1234abc@smtp-brevo.com
$env:NOTIFY_EMAIL_TO   = "you@example.com"
$env:NOTIFY_EMAIL_FROM = "you@your-verified-domain.com"   # MUST be a Brevo-verified sender. A plain @gmail.com / @outlook.com From fails DMARC and gets bounced or spam-foldered.
```

### A3. Gitignore the secret

Say why: *"This guarantees your private key file can never be committed by accident."* Ensure `.gitignore` contains the line `scripts/notify-email.local.ps1` (append if missing; create `.gitignore` if absent). **This MUST be in place before Part B writes any real secret.**

### A4. Append the notifications table to `CLAUDE.md`

Say why: *"This tells the build workflow WHEN to email you. It's the rulebook the EPCT flow reads."* Create `CLAUDE.md` if it doesn't exist; add this section verbatim unless already present:

```markdown
## MANDATORY: Development Notifications (email)

When running a multi-task pack with `/taskflow:epct-rn` or `/taskflow:epct-dotnet`, work the tasks one at a time and **run autonomously — do NOT stop for approval at plan or QA.** Just **email the task owner at the points below** to keep them informed. Send with:
`powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "<subject>" -Body "<body>"`
(The `-ExecutionPolicy Bypass -NoProfile` flags avoid the "running scripts is disabled on this system" error without changing any machine setting. Use `pwsh` instead of `powershell` if only PowerShell 7+ is installed.)
Email failures are non-fatal (log and continue). The ONLY time you STOP is a genuine blocker / needed intervention (row B).

| # | When | Stop? | Subject | Body |
|---|------|-------|---------|------|
| 1 | Task is starting | no — proceed | `[<TASK>] Started` | task name + what it covers |
| 2 | Plan is done | no — continue to Code | `[<TASK>] Plan done` | plan summary + acceptance criteria + risks |
| 3 | Task completed (QA finished) | no — next task | `[<TASK>] Done` | what shipped + QA verdict + any deferred items |
| 4 | All tasks completed (whole module) | done | `[<MODULE>] All tasks complete` | per-task summary + outstanding risks |
| B | **Blocker / intervention needed** (any phase) | **YES — STOP** | `[<TASK>] NEEDS YOUR INTERVENTION` | proper summary: what stopped it, why, and exactly what input is needed |
```

**After Part A, tell the user:** *"Plumbing done — those files are safe to commit. Now, do you want to turn on email notifications? It's optional."*

---

## Part B — Configure your email credentials (optional, interactive)

**Ask first** (AskUserQuestion): *"Configure email notifications now, or skip for later?"* — options "Configure now" / "Skip for now".

### If the user SKIPS

Explain clearly and finish:
> *"No problem — email is skipped. Everything still works: the build runs autonomously and still pauses in chat if it hits a blocker; it just won't also email you. To turn it on later, re-run `/taskflow:init` and choose 'Configure now'. Nothing else is needed."*

Do NOT block. Leave the `.example` in place. Part A files are already done.

### If the user CONFIGURES

First, **explain what you'll need and where it comes from** (share this — most setup failures are people not knowing where to get these):

> To send email, taskflow uses **Brevo** (a free email service). You'll need 4 values:
> 1. **`BREVO_SMTP_KEY`** — Brevo dashboard → **SMTP & API → SMTP** tab → your **SMTP key** (a long value; *not* the same as an API key). Create a free account at brevo.com if you don't have one.
> 2. **`BREVO_SMTP_LOGIN`** — on the same SMTP page, the **login** value, e.g. `1234abc@smtp-brevo.com`.
> 3. **`NOTIFY_EMAIL_FROM`** — the "from" address. This **must be a sender you've verified in Brevo** (see "How to add & verify a sender" below). A bare `@gmail.com`/`@outlook.com`/`@yahoo.com` will be rejected or spam-foldered (see the DMARC note in step 4 of the fill-in list).
> 4. **`NOTIFY_EMAIL_TO`** — where you want the notifications delivered (any inbox, e.g. your work email).

**How to add & verify a sender in Brevo (tell the user this — the FROM address won't work until it's verified):**
> In Brevo: click your **account name (top-right) → Senders, Domains & Dedicated IPs** (or go to **Settings → Senders & Domains**) → **Senders** tab → **Add a sender** → enter a name + the from-email → **Save**. Brevo then emails a **confirmation link to that address — open it and click to verify.** Once it shows a green "verified" check, use that exact address as `NOTIFY_EMAIL_FROM`.
> - Faster for a whole company domain: verify the **domain** (Domains tab → add DNS records) so any `@yourcompany.com` address works — but a single verified sender is enough to start.
> - Direct link: https://app.brevo.com/senders/list

Then walk the user through filling in the credentials **in the real file**:

1. **Confirm `.gitignore` protection.** Verify `.gitignore` contains `scripts/notify-email.local.ps1` (from A3). If not, STOP and fix it first — never create a secret file at an un-ignored path.
2. **Don't overwrite.** If `scripts/notify-email.local.ps1` already exists, leave it, say "already present", and skip to the test.
3. **Create the real credentials file `scripts/notify-email.local.ps1`** (a copy of the template, NOT the `.example`) with clearly-labelled placeholders the user will replace. Write exactly:

   ```powershell
   # GITIGNORED — never commit. Replace each <...> below with your real Brevo values, then save.
   $env:BREVO_SMTP_KEY    = "<your-brevo-smtp-key>"      # Brevo > SMTP & API > SMTP tab > SMTP key (NOT the API key)
   $env:BREVO_SMTP_LOGIN  = "<your-brevo-smtp-login>"    # same SMTP page, e.g. 1234abc@smtp-brevo.com
   $env:NOTIFY_EMAIL_FROM = "<verified-sender@your-domain>"  # a sender you've VERIFIED in Brevo
   $env:NOTIFY_EMAIL_TO   = "<where-to-send@example.com>"    # inbox that should receive notifications
   ```

4. **Now give the user explicit, numbered fill-in instructions** — this is the phase they asked about. Show them the exact path and the exact steps. Present it like this (fill in the real project path for `<project>`):

   > **Your private credentials file is ready. Here's how to fill it in:**
   >
   > 1. **Open the file:** `scripts/notify-email.local.ps1`
   >    (full path: `<project>/scripts/notify-email.local.ps1`). It's gitignored — it stays on your machine and is never committed.
   > 2. **Replace the 4 placeholders** with your real Brevo values, then **save**:
   >    - `BREVO_SMTP_KEY` → Brevo → **SMTP & API → SMTP** tab → your **SMTP key** (a long value; *not* the API key)
   >    - `BREVO_SMTP_LOGIN` → same SMTP page, e.g. `1234abc@smtp-brevo.com`
   >    - `NOTIFY_EMAIL_FROM` → a sender you've **verified** in Brevo (Senders, Domains & Dedicated IPs)
   >    - `NOTIFY_EMAIL_TO` → the inbox where you want notifications
   > 3. ⚠️ **Edit THIS file only** — `notify-email.local.ps1` (NOT `notify-email.local.ps1.example`; the script never reads the `.example`).
   > 4. **Save the file, then tell me "done"** — I'll send a test email to confirm it works.

   - **Warn on a free-mail FROM:** if they intend to use `@gmail.com`/`@outlook.com`/`@yahoo.com` for `NOTIFY_EMAIL_FROM`, tell them: *"Free-mail domains publish a strict DMARC policy, so Brevo can't sign as them — mail to other people will bounce or land in spam (a test to your own account may still look fine). Use a Brevo-verified domain sender instead."*
5. **Wait for the user to confirm they've saved the file.** Do not proceed to the test until they say they're done. (If the user would rather not open the file, they can paste the 4 values in chat and you'll fill them in for them — but the file-edit path is the default and keeps secrets out of the chat.)

---

## Part C — Send a test email + verify (only if configured in Part B)

Tell the user: *"Now I'll send one real test email to confirm it works end-to-end."* Then run this (the `-ExecutionPolicy Bypass -NoProfile` flags are included **up front** so the send isn't blocked by Windows' script-execution policy):

```
powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "taskflow test" -Body "hello"
```

(Use `pwsh` instead of `powershell` if only PowerShell 7+ is installed.)

- **If it prints `SUCCESS: email sent to …`** → tell them: *"Sent. Check that inbox (and spam on the first send). If it arrived, you're fully set up."*
- **If it prints `FAILED: …`** → do NOT just report the raw error. Diagnose it against the table below and tell the user exactly what to do, then offer to retry.
- **If the shell itself refuses to run the script** (e.g. *"running scripts is disabled on this system"* / `UnauthorizedAccess` — an execution-policy block, not a `FAILED:` from the script) → **retry automatically with the bypass form above.** The command already includes `-ExecutionPolicy Bypass -NoProfile`; if you ran a stripped-down version and hit this, re-run the full command. This bypass is per-invocation only and changes no machine setting, so it's safe to apply directly.

### Troubleshooting the test send

| Error contains… | What it means | What the user should do |
|---|---|---|
| *"running scripts is disabled"* / `UnauthorizedAccess` / execution policy | Windows blocked running the `.ps1` | Re-run with the bypass form: `powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "taskflow test" -Body "hello"`. (You can do this for the user directly — it's safe and per-command only.) |
| `unauthorized` / `authentication failed` / `535` | Wrong SMTP key or login | Re-copy the **SMTP key** and **login** from Brevo → SMTP & API → SMTP tab. The SMTP key is different from an API key. |
| **IP / "not authorized" / send blocked** (or a Brevo email titled *"A new IP address tried to log in"*) | **Brevo's IP whitelisting** blocked this machine (see next section) | Authorize your IP in Brevo — full steps below. |
| `sender` / `from` / `not verified` | The FROM address isn't a verified Brevo sender | Verify the sender in Brevo (Senders & Domains) or switch FROM to one that's already verified. |
| `missing email config` | The private file wasn't read | Confirm `scripts/notify-email.local.ps1` exists (not the `.example`) with all four `$env:` lines. |

---

## IP whitelisting (Brevo "Authorized IPs") — explain this clearly

**What it is and why it exists:** Brevo has an anti-abuse security feature called **Authorized IPs**. If someone steals your SMTP key, they still can't send unless they send from an IP address Brevo trusts. So the *first* time you send from a new network/computer, Brevo may **block the send** and email the account owner a message like *"A new IP address tried to access your account — was this you?"* until you approve that IP.

**How to complete it (two ways):**

1. **Easiest — approve from the email:** Right after the failed test, check the inbox of your **Brevo account owner email**. Open Brevo's *"authorize this new IP"* message and click the **authorize/allow** button. Then re-run the Part C test — it should now succeed.
2. **Manually in the dashboard:** Brevo → **Settings → Security → Authorized IPs** (wording may vary slightly). Add your machine's **current public IP** (find it at e.g. `https://ifconfig.me` or by searching "what is my IP"). Save, then re-run the test.

**Good to know (tell the user):**
- Your public IP can **change** (home routers, VPNs, mobile hotspots, moving between offices). If notifications suddenly start failing later with an IP error, just authorize the new IP the same way.
- If your whole team sends from the same office/VPN, whitelisting that IP once covers everyone on it.
- If your Brevo plan lets you turn the restriction off entirely and you accept the lower security, you can disable Authorized IPs — but approving the IP is the recommended path.

---

## Final summary (always end with this)

Report a short, structured wrap-up so the user knows the state and the next move:

1. **What was created vs. already present** — list the files (ps1 / example / .gitignore line / CLAUDE.md section).
2. **Email status** — one of: *Configured & test passed* · *Configured but test failed (with the fix to try)* · *Skipped (how to enable later)*.
3. **What to do next** — always end with:
   > *"Setup is done. Next, scaffold a feature with `/taskflow:autocode <Module>` (creates the task-pack folder), then start the build with `/taskflow:epct-rn` (React Native) or `/taskflow:epct-dotnet` (.NET). You'll get emails at task-start, plan-done, task-done, and all-done."*
