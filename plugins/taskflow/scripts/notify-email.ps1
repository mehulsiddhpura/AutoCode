<#
.SYNOPSIS
  Sends a notification email via the Brevo SMTP relay.

.DESCRIPTION
  Reusable across any module. Used by the taskflow EPCT "Development Notifications"
  gates to email the task owner on start-of-task, blockers/intervention, plan/QA
  gates, task-done, and all-work-done.

  The SMTP key is read from the BREVO_SMTP_KEY environment variable. If that is not
  set, the script dot-sources scripts\notify-email.local.ps1 (gitignored) which is
  expected to set $env:BREVO_SMTP_KEY. If the key is still missing, the script prints
  an error and exits non-zero WITHOUT throwing, so a missing key never aborts the
  surrounding workflow.

  Set -To / -From / -Login (and the Brevo key) to your own values, or pass them in.

.EXAMPLE
  powershell -File scripts/notify-email.ps1 -Subject "[TASK-1] Done" -Body "Shipped on feature/x"
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

# --- Resolve secrets/config (env var first, then gitignored local file) ---
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
    Write-Output "FAILED: missing email config. Create scripts/notify-email.local.ps1 (see notify-email.local.ps1.example) with your Brevo key + To/From/Login."
    exit 1
}

# --- Send ---
$client = $null
$msg = $null
try {
    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = $From
    $msg.To.Add($To)
    $msg.Subject = $Subject
    $msg.Body = $Body

    $client = New-Object System.Net.Mail.SmtpClient($Server, $Port)
    $client.EnableSsl = $true
    $client.Credentials = New-Object System.Net.NetworkCredential($Login, $key)
    $client.Send($msg)

    Write-Output "SUCCESS: email sent to $To"
    exit 0
}
catch {
    $reason = $_.Exception.Message
    if ($_.Exception.InnerException) { $reason = "$reason | $($_.Exception.InnerException.Message)" }
    Write-Output "FAILED: $reason"
    exit 1
}
finally {
    if ($msg) { $msg.Dispose() }
    if ($client) { $client.Dispose() }
}
