# taskflow — Claude Code plugin

taskflow adds a set of `/taskflow:*` slash commands to Claude Code that help you
plan and build software feature-by-feature — with built-in review, QA, and
approval gates. It works for both **React Native** (mobile) and **.NET** (backend)
projects.

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

```text
# Once per project — sets up the workflow (and optional email notifications)
/taskflow:init

# Then scaffold and build a feature
/taskflow:autocode Payroll
```

`autocode` will ask you a few questions (module name, your PRD, a Figma link for
React Native, or an API doc for .NET), generate a task pack, and then build it
task-by-task — pausing for your approval and after QA.

---

## The commands

| Command | What it does |
|---|---|
| `/taskflow:autocode <Module>` | **Start here.** Turns a PRD (+ Figma or API doc) into a task pack and builds it with gates. |
| `/taskflow:init` | One-time project setup (run once per project). |
| `/taskflow:epct <task>` | Guided build for **React Native**: Explore → Plan → Code → Review → QA → Commit. |
| `/taskflow:epct-dotnet <task>` | The same guided build for **.NET / backend**. |
| `/taskflow:rnreviewer` | Reviews React Native + TypeScript code. |
| `/taskflow:pr-reviewer` | Reviews a PR (.NET / React / React Native / Kotlin). |
| `/taskflow:qa-module <Module>` | Runs an automated QA pass on a module. |
| `/taskflow:gitworkflow` | Branch, commit, and push with a clean, structured flow. |
| `/taskflow:platformfix <symptom>` | iOS/Android fix reference for common platform issues. |

You can always run a command on its own — e.g. `/taskflow:epct Add login screen`.

---

## Updating to the latest version

When a new version is published, run this inside Claude Code:

```text
/plugin marketplace update taskflow
/reload-plugins
```

---

## Troubleshooting

- **Commands don't show up?** Run `/reload-plugins`, then type `/taskflow:` again.
- **Install failed at step 1?** Make sure you typed the repo exactly: `mehulsiddhpura/AutoCode`.
- **Email notifications?** They're optional — set them up during `/taskflow:init`. See
  [MAINTAINING.md](MAINTAINING.md) for details.

---

## For maintainers / contributors

The technical details — repo layout, how to edit skills, how to publish updates,
and the email-notification setup — live in **[MAINTAINING.md](MAINTAINING.md)**.
