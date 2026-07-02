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

Building a feature is **two steps** — first scaffold the task pack, then start the build.

> **Note:** `Payroll` below is just an **example module name** — replace it with your own
> (e.g. `Invoices`, `Login`, `Reports`). Whatever name you use, autocode creates a
> matching `<name>-tasks/` folder, so `Invoices` → `invoices-tasks/`.

**Generic form** (what to type for any module — replace `<Module>`):

```text
# Once per project — sets up the workflow (and optional email notifications)
/taskflow:init

# Step 1 — scaffold the task pack (creates a <module>-tasks/ folder)
/taskflow:autocode <Module>

# Step 2 — when you're ready, start building from that pack
/taskflow:epct Build the complete <Module> module from <module>-tasks/README.md — one task at a time.
#   (use /taskflow:epct-dotnet instead for a .NET backend module)
```

**Filled-in example** (using the module name `Payroll`):

```text
/taskflow:autocode Payroll
/taskflow:epct Build the complete Payroll module from payroll-tasks/README.md — one task at a time.
```

You don't have to memorize the Step 2 text — after Step 1, autocode **prints the exact
build command with your module name already filled in**, so you just copy-paste it.

**Step 1** (`autocode`) asks you a few questions (module name, your PRD, a Figma
link for React Native, or an API doc for .NET), then generates the task-pack
folder and **stops** — it does *not* start building on its own.

**Step 2** (`epct` / `epct-dotnet`) is when the actual build runs — task-by-task on
its own, emailing you when each task starts, when its plan is ready, when it's done,
and when the whole module is finished. It only stops to ask you if it hits a blocker.

---

## The commands

| Command | What it does |
|---|---|
| `/taskflow:autocode <Module>` | **Start here.** Turns a PRD (+ Figma or API doc) into a task-pack folder. Then run `epct`/`epct-dotnet` to build it. |
| `/taskflow:init` | One-time project setup — guided, step-by-step email setup (run once per project). |
| `/taskflow:epct <task>` | Autonomous build for **React Native**: Explore → Plan → Code → Review → QA (emails you at each milestone). |
| `/taskflow:epct-dotnet <task>` | The same autonomous build for **.NET / backend**: Explore → Plan → Code → Test → QA. |
| `/taskflow:rnreviewer` | Reviews React Native + TypeScript code. |
| `/taskflow:pr-reviewer` | Reviews a PR (.NET / React / React Native / Kotlin). |
| `/taskflow:qa-module <Module>` | Runs an automated QA pass on a module. |
| `/taskflow:gitworkflow` | Branch, commit, and push with a clean, structured flow. |
| `/taskflow:platformfix <symptom>` | iOS/Android fix reference for common platform issues. |

You can always run a command on its own — e.g. `/taskflow:epct Add login screen`.

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
| **From address** | A sender you've **verified** under **Senders, Domains & Dedicated IPs** |
| **To address** | Any inbox where you want the notifications delivered |

> ⚠️ **Use a verified sender for the "From" address.** A plain `@gmail.com` / `@outlook.com`
> "From" gets rejected or spam-foldered (those domains block Brevo from signing as them).
> A test to your own account may still look fine — but mail to teammates won't arrive.

### What `init` does

```text
/taskflow:init
```

1. **Creates the plumbing** (safe to commit, no secrets): the sender script
   `scripts/notify-email.ps1`, a template `.example` file, a `.gitignore` rule to protect
   your key, and a notifications table in your `CLAUDE.md` that tells the build when to email.
2. **Asks if you want email on now** — pick "Configure now" or "Skip for later".
3. **If you configure:** it asks for the 4 Brevo values above and writes your **private,
   gitignored** credentials file for you (you never hand-edit the `.example`).
4. **Sends one real test email** and tells you whether it worked — and if not, exactly what to fix.

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
