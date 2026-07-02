# Maintaining taskflow

This doc is for **maintainers and contributors** of the taskflow plugin. If you
just want to install and use it, see [README.md](README.md).

This repo is **both a Claude Code marketplace and the plugin** it serves.

## What the plugin provides (`/taskflow:<skill>`)

| Command | What it does |
|---|---|
| `/taskflow:autocode <Module>` | **Headliner.** Interviews you, reads the PRD + Figma (+ optional API doc), generates a `<module>-tasks/` pack (README + per-screen specs + QA scenarios + CSV), then **stops and tells you the command to start the build** (it does not auto-start). |
| `/taskflow:init` | One-time per-project setup: writes `scripts/notify-email.ps1`, gitignores the secret, and adds the Development Notifications table to `CLAUDE.md`. |
| `/taskflow:epct-rn <task>` | 5-phase Explore → Plan → Code → Review → QA for React Native. Runs autonomously with email notifications; no approval gates. Committing is not part of the flow — run `/taskflow:gitworkflow` separately. |
| `/taskflow:epct-dotnet <task>` | The EPCT flow for any .NET work — API endpoints, Razor/MVC/Blazor pages, or full-stack (Explore → Plan → Code → Test → QA), also autonomous. |
| `/taskflow:rn-reviewer` | Senior React Native + TypeScript reviewer (10 dimensions). |
| `/taskflow:pr-reviewer-dotnet` | Production PR reviewer for .NET / React / RN / Kotlin. |
| `/taskflow:gitworkflow` | Sync main → feature branch → staged-files table → structured commit → push. |
| `/taskflow:qa-module-rn <Module>` | Automated QA pipeline (discover, tests, device verify, report). |
| `/taskflow:platformfix-rn <symptom>` | iOS/Android platform-fix reference handbook. |

### Project types — one mobile track + four .NET shapes

`/taskflow:autocode` asks what kind of project you're building and generates the matching pack; you then run the matching EPCT to build it. There are **five project types** across two build engines:

| # | Project type | Pack unit → folder | Build with | Reviewers |
|---|---|---|---|---|
| 1 | **React Native** (mobile) | screen → `screens/` | `/taskflow:epct-rn` | `rn-reviewer` · `platformfix-rn` · `qa-module-rn` |
| 2 | **.NET — HTML only** (Razor/MVC) | page → `pages/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 3 | **.NET — Frontend** (UI calling an API) | page → `pages/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 4 | **.NET — Backend** (Web API) | endpoint → `endpoints/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 5 | **.NET — Frontend + Backend** | both → `pages/` + `endpoints/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |

Build engine: type 1 → `/taskflow:epct-rn`; types 2–5 → `/taskflow:epct-dotnet`. Inputs autocode accepts: a plain description, and optionally a **PRD**, a **Figma link** (UI types), and **API documentation** (Backend / Frontend-that-calls-an-API).

Generating the pack (`autocode`) and building it (`epct` / `epct-dotnet`) are **two separate steps** — autocode stops after creating the folder. `/taskflow:gitworkflow` and `/taskflow:init` are shared by all types. You can also run an EPCT directly: `/taskflow:epct-rn <task>` (React Native) or `/taskflow:epct-dotnet <task>` (any .NET type).

## Zero-touch per project (optional)

Commit this to a project's `.claude/settings.json` so teammates who trust the project get the plugin auto-enabled:

```json
{
  "extraKnownMarketplaces": {
    "taskflow": {
      "source": { "source": "github", "repo": "mehulsiddhpura/AutoCode" }
    }
  },
  "enabledPlugins": {
    "taskflow@taskflow": true
  }
}
```

(For a Bitbucket/self-hosted git remote, use `"source": { "source": "git", "url": "https://bitbucket.org/<workspace>/<repo>.git" }`.)

## Email notifications

The flow emails the task owner at task-start, plan-done, task-done, all-tasks-done, and on any blocker / needed intervention (with a summary), via `scripts/notify-email.ps1` (Brevo SMTP). The key is **never committed** — each dev copies `scripts/notify-email.local.ps1.example` → `scripts/notify-email.local.ps1` (gitignored) and fills in their Brevo key + recipient, or sets the `BREVO_SMTP_KEY` / `NOTIFY_EMAIL_*` env vars. A cross-platform `notify-email.sh` (curl) is included for macOS/Linux.

## Repo layout

```
AutoCode/
├── .claude-plugin/marketplace.json     # the marketplace
└── plugins/taskflow/
    ├── .claude-plugin/plugin.json      # the plugin manifest
    ├── skills/<name>/SKILL.md          # autocode, init, epct, epct-dotnet, rn-reviewer,
    │                                   # pr-reviewer-dotnet, gitworkflow, qa-module-rn, platformfix-rn
    └── scripts/                        # notify-email.ps1 / .sh / .local.ps1.example
```

## Publishing an update

1. Edit a skill under `plugins/taskflow/skills/<name>/SKILL.md`.
2. Bump `version` in `plugins/taskflow/.claude-plugin/plugin.json`.
3. Commit & push.
4. Teammates run `/plugin marketplace update taskflow` then `/reload-plugins`.

> Before publishing: set your team name in `marketplace.json` + `plugin.json` (`owner`/`author`), and the recipient/sender in `scripts/notify-email.local.ps1` (local only).
