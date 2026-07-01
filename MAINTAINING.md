# Maintaining taskflow

This doc is for **maintainers and contributors** of the taskflow plugin. If you
just want to install and use it, see [README.md](README.md).

This repo is **both a Claude Code marketplace and the plugin** it serves.

## What the plugin provides (`/taskflow:<skill>`)

| Command | What it does |
|---|---|
| `/taskflow:autocode <Module>` | **Headliner.** Interviews you, reads the PRD + Figma (+ optional API doc), generates a `<module>-tasks/` pack (README + per-screen specs + QA scenarios + CSV), then auto-starts the gated build. |
| `/taskflow:init` | One-time per-project setup: writes `scripts/notify-email.ps1`, gitignores the secret, and adds the notification gate table to `CLAUDE.md`. |
| `/taskflow:epct <task>` | 6-phase Explore → Plan → Code → Review → QA → Commit for React Native, with **APPROVED** and **QA PASSED** gates. |
| `/taskflow:epct-dotnet <task>` | The EPCT flow for .NET / backend work. |
| `/taskflow:rnreviewer` | Senior React Native + TypeScript reviewer (10 dimensions). |
| `/taskflow:pr-reviewer` | Production PR reviewer for .NET / React / RN / Kotlin. |
| `/taskflow:gitworkflow` | Sync main → feature branch → staged-files table → structured commit → push. |
| `/taskflow:qa-module <Module>` | Automated QA pipeline (discover, tests, device verify, report). |
| `/taskflow:platformfix <symptom>` | iOS/Android platform-fix reference handbook. |

### Two tracks — React Native or .NET

`/taskflow:autocode` asks which stack you're on and drives the matching flow end-to-end:

| Track | Pack it generates | Auto-chains into | Reviewers used |
|---|---|---|---|
| **React Native** | screen-by-screen (Figma-driven UI) | `/taskflow:epct` | `/taskflow:rnreviewer` · `/taskflow:platformfix` · `/taskflow:qa-module` |
| **.NET** | endpoint/feature (API-driven, Controller→Service→Repository) | `/taskflow:epct-dotnet` | `/taskflow:pr-reviewer` |

`/taskflow:gitworkflow` and `/taskflow:init` are shared by both tracks. You can also run any EPCT directly: `/taskflow:epct <task>` for RN, `/taskflow:epct-dotnet <task>` for .NET.

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

The gates email the task owner (start / blocker / plan-ready / QA / done) via `scripts/notify-email.ps1` (Brevo SMTP). The key is **never committed** — each dev copies `scripts/notify-email.local.ps1.example` → `scripts/notify-email.local.ps1` (gitignored) and fills in their Brevo key + recipient, or sets the `BREVO_SMTP_KEY` / `NOTIFY_EMAIL_*` env vars. A cross-platform `notify-email.sh` (curl) is included for macOS/Linux.

## Repo layout

```
AutoCode/
├── .claude-plugin/marketplace.json     # the marketplace
└── plugins/taskflow/
    ├── .claude-plugin/plugin.json      # the plugin manifest
    ├── skills/<name>/SKILL.md          # autocode, init, epct, epct-dotnet, rnreviewer,
    │                                   # pr-reviewer, gitworkflow, qa-module, platformfix
    └── scripts/                        # notify-email.ps1 / .sh / .local.ps1.example
```

## Publishing an update

1. Edit a skill under `plugins/taskflow/skills/<name>/SKILL.md`.
2. Bump `version` in `plugins/taskflow/.claude-plugin/plugin.json`.
3. Commit & push.
4. Teammates run `/plugin marketplace update taskflow` then `/reload-plugins`.

> Before publishing: set your team name in `marketplace.json` + `plugin.json` (`owner`/`author`), and the recipient/sender in `scripts/notify-email.local.ps1` (local only).
