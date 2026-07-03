# taskflow — Claude Code plugin

taskflow adds a set of `/taskflow:*` slash commands to Claude Code that help you
plan and build software feature-by-feature — with built-in review and QA. It runs
autonomously and emails you at each milestone (task start, plan done, task done,
all done) and whenever it hits a blocker. It works for both **React Native**
(mobile) and **.NET** (backend) projects.

You don't need to understand how it's built to use it. Just add it, then type
`/taskflow:` in Claude Code and pick a command.

---

## Requirements

- **Claude Code** installed and working (the `/plugin` command is available inside it).
- A **git repository** for your project (most commands assume you're in one).

---

## Install (3 steps)

Run these **inside Claude Code** (type them at the prompt, one at a time):

```text
1.  /plugin marketplace add mehulsiddhpura/AutoCode
2.  /plugin install taskflow@taskflow
3.  /reload-plugins
```

That's it. Now type `/taskflow:` and your commands will appear in the list.

> **Tip:** If step 1 asks about trusting the source, confirm to continue.

---

## Try it

Building a feature is **three simple steps**. Type each command inside Claude Code.

> **Replace `<YourModule>` with your own feature name** (e.g. `Invoices`, `Login`, `Reports`).
> Whatever you name it, autocode makes a matching `<your-module>-tasks/` folder — so `Invoices`
> → `invoices-tasks/`, `Login` → `login-tasks/`.

### Step 0 — set up the project (once)

```text
/taskflow:init
```

**What you'll get:** a guided setup that creates the workflow files and (optionally) turns on
email notifications. Run it once per project. → see [email setup](#setting-up-email-notifications-optional-but-recommended) below.

### Step 1 — describe your feature → get a task pack

```text
/taskflow:autocode <YourModule>
```

**What happens:** it asks you, in plain words, *what you want to build* — the feature name, a
one-line goal, and a list of the screens/pages/actions you want. No formal document needed —
though you can attach any of a **PRD**, a **Figma link**, or **API documentation** for a better
pack. It also asks what kind of project it is (pick one):

| Project type | What it builds |
|---|---|
| **React Native** | Mobile app screens (iOS + Android) |
| **.NET — HTML only** | Server-rendered pages (Razor Pages / MVC) |
| **.NET — Frontend** | A .NET UI (Razor/MVC/Blazor) that calls an API |
| **.NET — Backend** | A Web API (no UI) |
| **.NET — Frontend + Backend** | Full-stack: the API **and** the .NET UI |

**What you'll get:** a new **`<your-module>-tasks/`** folder — one file per task (a screen, a page,
or an endpoint), a build-order list, and a `README.md`. Then it **stops** and shows you the exact
command to start building. *(It does not build automatically.)*

### Step 2 — build it

```text
/taskflow:epct-rn Build the complete <YourModule> module from <your-module>-tasks/README.md — one task at a time.
```
*(This is the React Native command. For .NET use `/taskflow:epct-dotnet` (API / Frontend / full-stack)
or `/taskflow:epct-design-dotnet` (HTML-only UI) instead. You don't have to type this by hand —
**Step 1 prints the exact command with your module name already filled in**; just copy-paste it.)*

**What you'll get:** the build runs on its own, one task at a time (Explore → Plan → Code →
Review → QA), and **emails you** at each milestone — task started, plan ready, task done, and
all tasks done. It only stops to ask you if it hits a **blocker**.

---

## The commands

| Command | What it does |
|---|---|
| `/taskflow:autocode <Module>` | **Start here.** Ask it to build a feature (describe it, or share a PRD/Figma/API doc) → it creates a task-pack folder. Then run `epct`/`epct-dotnet` to build it. |
| `/taskflow:init` | One-time project setup — guided, step-by-step email setup (run once per project). |
| `/taskflow:epct-rn <task>` | Autonomous build for **React Native**: Explore → Plan → Code → Review → QA (emails you at each milestone). |
| `/taskflow:epct-dotnet <task>` | The same autonomous build for **.NET** (API endpoints, Razor/MVC/Blazor pages, or full-stack): Explore → Plan → Code → Test → QA. |
| `/taskflow:epct-design-dotnet <task>` | Theme-locked UI builder for **.NET HTML-only** (ASP.NET MVC Razor + jQuery + Bootstrap). Studies your house style, then builds native-looking pages with static demo data. |
| `/taskflow:rn-reviewer` | Reviews React Native + TypeScript code. |
| `/taskflow:pr-reviewer-dotnet` | Reviews a PR (.NET / React / React Native / Kotlin). |
| `/taskflow:qa-module-rn <Module>` | Runs an automated QA pass on a module. |
| `/taskflow:gitworkflow` | Branch, commit, and push with a clean, structured flow. |
| `/taskflow:platformfix-rn <symptom>` | iOS/Android fix reference for common platform issues. |

You can always run a command on its own — e.g. `/taskflow:epct-rn Add login screen`.

---

## Setting up email notifications (optional, but recommended)

The build can email you at each milestone (task start, plan done, task done, all done)
and whenever it needs your help. This is **optional** — if you skip it, the workflow
still runs and still pauses in chat when it hits a blocker; it just won't also email you.

`/taskflow:init` walks you through this step-by-step and **tells you what happened, why,
and what to do next after every step.** Here's the whole picture so you know what to expect.

### Before you start: get a free Brevo account

taskflow sends mail through **[Brevo](https://www.brevo.com)** (free tier is plenty). Once
signed in, you'll need **4 values** — `init` will ask you for them:

| Value | Where to find it in Brevo |
|---|---|
| **SMTP key** | **SMTP & API → SMTP** tab → your SMTP key (this is *not* the API key) |
| **SMTP login** | Same SMTP page, e.g. `1234abc@smtp-brevo.com` |
| **From address** | A sender you've **verified** (see steps below) |
| **To address** | Any inbox where you want the notifications delivered |

#### Add & verify your "From" sender in Brevo (required)

Brevo won't send from an address you haven't verified. To add one:

1. In Brevo, click your **account name (top-right) → Senders, Domains & Dedicated IPs**
   (or **Settings → Senders & Domains**) — direct link: <https://app.brevo.com/senders/list>
2. Open the **Senders** tab → **Add a sender** → enter a name and the from-email → **Save**.
3. Brevo emails a **confirmation link to that address** — open it and click to **verify**.
4. Once it shows a green **"verified"** check, use that exact address as your **From address**.

*(Tip: to make any `@yourcompany.com` address work, verify the whole **domain** under the
Domains tab via DNS records — but one verified sender is enough to get started.)*

> ⚠️ **Don't use a plain `@gmail.com` / `@outlook.com` / `@yahoo.com` as the From address.**
> Those domains block Brevo from signing as them, so mail gets rejected or spam-foldered. A test
> to your own account may still look fine — but mail to teammates won't arrive. Use a verified
> sender on your own domain.

### What `init` does

```text
/taskflow:init
```

1. **Creates the plumbing** (safe to commit, no secrets): the sender script
   `scripts/notify-email.ps1`, a template `.example` file, a `.gitignore` rule to protect
   your key, and a notifications table in your `CLAUDE.md` that tells the build when to email.
2. **Asks if you want email on now** — pick "Configure now" or "Skip for later".
3. **If you configure:** it creates your **private, gitignored** credentials file and then asks
   you to fill it in. Do this:
   1. Open **`scripts/notify-email.local.ps1`** (in *your project* folder). It's gitignored, so it
      never gets committed.
   2. Replace the 4 placeholders with your real Brevo values (from the table above) and **save**:
      ```powershell
      $env:BREVO_SMTP_KEY    = "your-smtp-key"
      $env:BREVO_SMTP_LOGIN  = "1234abc@smtp-brevo.com"
      $env:NOTIFY_EMAIL_FROM = "verified-sender@your-domain.com"
      $env:NOTIFY_EMAIL_TO   = "you@example.com"
      ```
   3. ⚠️ Edit **`notify-email.local.ps1`** only — *not* `notify-email.local.ps1.example` (the
      script never reads the `.example`; editing it is the #1 setup mistake).
   4. Tell Claude **"done"**.

   *(Prefer not to open a file? You can paste the 4 values in chat instead and init will write
   them into the file for you.)*
4. **It then sends one real test email.**
   **What you'll get:** a `taskflow test` email in your **To** inbox (check spam on the first send).
   If it arrives, you're fully set up. If not, init tells you exactly what to fix — see below.

### If PowerShell says "running scripts is disabled on this system"

This is a Windows **execution-policy** block, not an email problem. The fix is to run the sender
with a per-command bypass (it changes no machine setting):

```text
powershell -ExecutionPolicy Bypass -NoProfile -File scripts/notify-email.ps1 -Subject "taskflow test" -Body "hello"
```

The plugin already uses this form everywhere, so you normally won't hit it — but if you run the
script manually and see the error, add `-ExecutionPolicy Bypass -NoProfile` as shown.

### If the test email fails: IP whitelisting

The most common first-time failure is **Brevo's "Authorized IPs"** security check.

- **What it is:** Brevo blocks sending from an unrecognized computer/network even if your key
  is correct — an anti-abuse safeguard. The first send from a new IP is held until you approve it.
- **How to fix it (easiest):** Check the inbox of your **Brevo account-owner email** right after
  the failed test. Brevo sends a *"a new IP address tried to access your account"* message —
  open it and click **authorize**. Then run the test again (`/taskflow:init` will offer to retry).
- **Or do it manually:** In Brevo go to **Settings → Security → Authorized IPs**, add your
  machine's current public IP (find it at [ifconfig.me](https://ifconfig.me)), save, and retry.
- **Note:** your public IP can change (VPN, home router, new office). If emails start failing
  later with an IP error, just authorize the new IP the same way. One office/VPN IP covers
  everyone sending from it.

### Turning it on later / changing credentials

Just re-run `/taskflow:init` and choose "Configure now" — it's safe to run again (it won't
overwrite an existing credentials file, and it'll tell you what's already in place).

---

## Updating to the latest version

When a new version is published, run this inside Claude Code:

```text
/plugin marketplace update taskflow
/reload-plugins
```

---

## Uninstall

To remove the plugin, run this inside Claude Code:

```text
/plugin uninstall taskflow@taskflow
/reload-plugins
```

Optionally, remove the marketplace source too (so it no longer appears as available):

```text
/plugin marketplace remove taskflow
```

> Prefer to keep it but turn it off temporarily? Run `/plugin` to open the plugin
> manager and toggle taskflow off — no uninstall needed.

---

## Troubleshooting

- **Commands don't show up?** Run `/reload-plugins`, then type `/taskflow:` again.
- **Install failed at step 1?** Make sure you typed the repo exactly: `mehulsiddhpura/AutoCode`.
- **Email not sending?** See [Setting up email notifications](#setting-up-email-notifications-optional-but-recommended)
  above — the most common cause is Brevo **IP whitelisting** (authorize your IP), followed by
  using an unverified "From" address.
- **Email notifications are optional** — skip them and the workflow still runs, just without emails.

---

## For maintainers / contributors

The technical details — repo layout, how to edit skills, how to publish updates,
and the email-notification setup — live in **[MAINTAINING.md](MAINTAINING.md)**.
