---
name: autocode
description: Describe a feature (in plain words, plus any PRD / Figma link / API documentation) and get an EPCT-ready task pack (folder of per-task specs). Supports five project types — React Native (mobile), .NET HTML-only, .NET Frontend, .NET Backend, and .NET Frontend+Backend. Stops after generating the pack and tells the user the command to start the build — it does NOT auto-start. Use when scaffolding a new module/feature.
---

# autocode — describe a feature → task pack (React Native OR .NET)

You are scaffolding a complete, accurate task pack for a new module. `$ARGUMENTS` is the module display name (e.g. "Payroll"). **Your job ends when the task-pack folder is generated** — you then tell the user which command starts the build. You do **not** start building automatically.

First figure out **what kind of project** the user is building — this decides the pack template, the per-task unit, and which build command they'll run. There are **five project types** across two build engines:

| # | Project type | What it is | Per-task unit → folder | Build engine | Reviewers |
|---|---|---|---|---|---|
| 1 | **React Native** (mobile frontend) | Mobile app screens (iOS + Android) | screen → `screens/` | `/taskflow:epct-rn` | `rn-reviewer`, `platformfix-rn`, `qa-module-rn` |
| 2 | **.NET — HTML only** | Server-rendered pages (Razor Pages / MVC views), forms post back; no separate SPA/API | page/view → `pages/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 3 | **.NET — Frontend** | A .NET UI (Razor/MVC/Blazor) that calls a backend API | page/view → `pages/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 4 | **.NET — Backend** | Web API only (Controller → Service → Repository, DTOs, EF Core) | endpoint/feature → `endpoints/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |
| 5 | **.NET — Frontend + Backend** | Full-stack: build both the API endpoints and the .NET UI pages | **both** → `pages/` + `endpoints/` | `/taskflow:epct-dotnet` | `pr-reviewer-dotnet` |

**Build engine:** type 1 → `/taskflow:epct-rn` (React Native). Types 2–5 → `/taskflow:epct-dotnet` (.NET).

Work the phases in order. Ask only for inputs you don't already have.

---

## Phase 0 — Understand what the user wants (keep it simple)

**Don't demand a formal PRD or make the user "select" a document.** Many users don't have a written PRD — that's fine. Invite them to **explain their case in plain words**, and let them attach whatever detail they already have.

### 0a. Ask them to explain their case (one friendly message)

> **Tell me what you want to build — no formal document needed.** Just give me the basics:
> 1. **Module/feature name** (e.g. "Payroll", "Login", "Invoices")
> 2. **What is it / what's the goal?** (one or two lines — your case, e.g. "Let employees view and download their payslips")
> 3. **What should it do?** (list the screens/pages or actions you want)
> 4. **Anything you already have** — attach any of these (all optional; more detail = a better pack):
>    - a **PRD** (paste it or give a file path),
>    - a **Figma link** (for the UI/design),
>    - **API documentation** (OpenAPI/Swagger file, endpoint list, or a doc).

### 0b. Confirm the project type (this drives everything)

Use **AskUserQuestion** in up to two quick steps (the tool allows ~4 options each):

1. **Is this React Native (a mobile app) or .NET?**
2. **If .NET, which kind?** — offer these four:
   - **HTML only** — server-rendered pages (Razor Pages / MVC), forms post back; no separate API.
   - **Frontend** — a .NET UI (Razor/MVC/Blazor) that calls a backend API.
   - **Backend** — a Web API only (no UI).
   - **Frontend + Backend** — full-stack: build both the API and the .NET UI.

Give a one-line hint with each so a non-expert can choose. Map the answer to project type **1–5** from the table above (this sets the per-task unit and the build command).

### 0c. Derive the rest; ask at most a couple of short follow-ups

- **Module name** → `kebab-name` (folder = `kebab-name-tasks/`), `PascalName`, `lowercamel`.
- **UI types (1 React Native, 2 HTML-only, 3 Frontend, and the UI half of 5):** Figma link/entry node if they have one; screen/page list; navigation/routes; out-of-scope. Figma is recommended but optional — proceed from their description, marking visuals `TBD` if absent.
- **API types (4 Backend, and the API half of 5):** API/contract source (OpenAPI/Swagger/endpoint list, optional), base route (`/api/<module>`), auth scheme (JWT/roles/policies), layering convention (Controller → Service → Repository, DTOs, EF Core `DbContext`), out-of-scope.
- **Frontend that calls an API (types 3 and 5):** which endpoints each page consumes (from the API doc if given; else `TBD`).
- If no API contract is given, scaffold `TBD — confirm with API doc` placeholders rather than blocking.

Skip any question already answered in `$ARGUMENTS` or the user's message. **Don't interrogate.**

---

## Phase 1 — Read the inputs

- **The user's description / PRD:** use whatever they gave — a plain-language list, pasted notes, or a PRD file/path. If it's a file, read it fully. Extract the feature/screen/page list, flows, and per-item details. If details are thin, infer sensible defaults from their stated goal and mark anything uncertain `TBD` (don't block).
- **Figma (any UI type — React Native, .NET HTML-only, .NET Frontend):** if the Figma MCP is connected, `get_metadata` on the entry node → child frames (one per screen/page); `get_design_context` per frame → UI elements/labels/colors; `download_assets` for icons. Record each node id. **Fallback (MCP off):** ask for the screen/page list or proceed from the description, marking nodes `TBD`.
- **API documentation (Backend, and any Frontend that calls an API):** parse the OpenAPI/Swagger/endpoint list → the set of endpoints (method, route, request/response DTO, auth, errors). If only a PRD, derive the endpoints/features from it. Map each unit → endpoints + sample request/response + error codes. For **Frontend** types, also note which endpoints each page calls.

---

## Phase 2 — Derive the build order

Produce an ordered task list. The **per-task unit depends on the project type:**
- **Type 1 (React Native)** and **types 2–3 (.NET HTML-only / Frontend):** one task per **screen/page** (Task 1 = the entry point / dashboard / landing page).
- **Type 4 (.NET Backend):** one task per **endpoint or cohesive feature** (Task 1 = the foundational CRUD-create or the read others depend on).
- **Type 5 (.NET Frontend + Backend):** order so each API endpoint comes **before** the page that consumes it (e.g. `GET payslips` endpoint, then the Payslip List page). Keep pages and endpoints as distinct tasks.

For each task capture its identity (screen/page name + Figma node, OR method+route), any endpoints it uses, status (`✅ done` / `🔲 stub`/`app-only` / `⬜ pending`), and dependencies/navigation.

Show the user the derived build-order table and let them correct it **before** writing files.

---

## Phase 3 — Generate the task pack

Create `<kebab-name>-tasks/` in the current project. **Use the template(s) for the chosen project type** (see the map below). Keep the convention blocks generic — only fill the parameterized values.

**Which template(s) to use:**
- **Type 1 (React Native)** → the *React Native (screens)* template.
- **Types 2 & 3 (.NET HTML-only / Frontend)** → the *.NET UI pages* template (tasks under `pages/`).
- **Type 4 (.NET Backend)** → the *.NET Backend (endpoints)* template (tasks under `endpoints/`).
- **Type 5 (.NET Frontend + Backend)** → generate **both**: `endpoints/` from the Backend template **and** `pages/` from the UI-pages template, under one `README.md` that lists both in build order.

### ▶ Type 1 — React Native (screens)

**`README.md`**
````markdown
# {{Module}} Mobile — Screen-wise Task Pack

Screen-by-screen task breakdown for the **{{Module}}** flow. Each screen is a task with its own context file under `screens/` containing the screen description, the exact API endpoints, and request/response samples.

- **Design (source of truth):** {{Figma URL}}
- **Full API contract:** {{API doc path or "TBD"}}

## Module & folder structure
Create a new **`{{lowercamel}}`** module mirroring the app's existing feature modules (screens, components, services, models, navigation). Don't invent a new structure.

## Build order
| # | Screen | Figma | Endpoints | Status |
|---|--------|-------|-----------|--------|
{{one row per screen task}}

## Shared conventions (apply to every screen)
**Base path:** `{{/api/<module>}}` · **Auth:** `Authorization: Bearer <jwt>`; token entity-id must match the `{id}` in the URL → 401 on mismatch.
**Envelopes:** `{ "success": true, "message": "OK", "data": {} }` / `{ "success": false, "message": "…", "errorCode": "…", "data": null }`.
**HTTP codes:** 200 · 400 · 401 · 404 · 422 · 500. **Dynamic lists** render in array order; totals are server-computed.

## App-side conventions (React Native — every screen)
- Works on **Android + iOS** (verify layout, nav, safe-area, platform behavior).
- `{{MODULE_URL}} = "{{dev url}}"` in the endpoints file; never hard-code the host.
- Read `{{id source}}` from local storage; never hard-code it.
- Render the shared `Loader` while a screen's API is in flight.
- Use the shared header component (`title` + `onBackPress` + optional flags).
- Every `<Text>` sets `fontSize`/`fontWeight`/color from the colors file (no raw hex); use `scale()`/`verticalScale()`.
- Null-safe everything (guard, placeholder, skip empty sections) — never crash.
- Money with 2 decimals; consistent date/id formatting.
- Proper stack navigation with a working back action.

| From | To |
|------|----|
{{navigation rows}}

## Testing scenarios
Maintain one combined [{{Pascal}}_scenarios.md]({{Pascal}}_scenarios.md); append each screen's scenarios during its EPCT QA phase. Cover happy path, switching/filters, empty/no-data, null-fields, downloads, Android + iOS.

## Notifications (email)
Drives `/taskflow:epct-rn`, which runs autonomously and emails the owner at task-start, plan-done, task-done, all-done, and on any blocker via `scripts/notify-email.ps1`. Run `/taskflow:init` once first.

## Status legend
✅ API done · 🔲 app-side only · ⬜ pending

> **Out of scope:** {{out-of-scope}}
````

**`screens/NN_<screen>.md`** (per task): `# Task N — <Screen>`; Figma node / Status / Endpoints; `## Purpose`; `## UI elements (from Figma)`; `## Navigation` (From/To); per-endpoint blocks (`METHOD /api/<module>/path/{id}` + param table + `### Sample response` JSON + `### Errors` + `### Field notes`); `## Notes`.

**`{{Pascal}}Tasks.csv`:** `#,Screen,Figma,Endpoints,Status` rows (opens in Excel).

> Do **not** generate the `{{Pascal}}_scenarios.md` file here — it is created and appended during each task's EPCT QA phase, after the work is done.

### ▶ Type 4 — .NET Backend (endpoints)

**`README.md`**
````markdown
# {{Module}} API — Endpoint-wise Task Pack

Endpoint/feature breakdown for the **{{Module}}** API. Each task has its own context file under `endpoints/` with the route, request/response DTOs, validation, business rules, and errors.

- **PRD / spec:** {{PRD path}}
- **API contract (OpenAPI/Swagger):** {{contract path or "TBD"}}

## Module & solution structure
Add the **`{{Pascal}}`** feature mirroring the solution's existing layering — **Controller → Service → Repository**, request/response **DTOs**, EF Core `DbContext`/entities, and DI registration. Don't invent a new structure.

## Build order
| # | Endpoint / Feature | Method + Route | Auth | Status |
|---|--------------------|----------------|------|--------|
{{one row per endpoint/feature task}}

## Shared conventions (apply to every endpoint)
**Base route:** `{{/api/<module>}}` · **Auth:** `{{JWT + roles/policies}}`; enforce ownership/authorization, return 401/403 appropriately.
**Response:** consistent success/error shape ({{envelope or ProblemDetails RFC 7807}}). **HTTP codes:** 200/201 · 400 (validation) · 401 · 403 · 404 · 409 (conflict) · 422 · 500.
**Pagination/filtering/sorting:** consistent query params; server-computed totals.

## Backend conventions (.NET — every endpoint)
- **Layering:** thin Controller (no business logic) → Service (rules) → Repository/EF (data). Register in DI.
- **DTOs:** explicit request/response DTOs; never expose EF entities directly; map (AutoMapper or manual).
- **Validation:** {{FluentValidation/DataAnnotations}} on every request; return 400 with field errors.
- **Async + `CancellationToken`** on all I/O; no blocking calls.
- **EF Core:** migrations for schema changes; no N+1; use projections; transactions where needed.
- **Security:** authorize every endpoint; no secrets in code/appsettings (use user-secrets/KeyVault); validate all input; parameterized queries only.
- **Errors:** central exception handling → ProblemDetails; never leak stack traces.
- **Logging:** structured logs (no PII/secrets). **Tests:** unit (Service) + integration (endpoint) for each task.

## Testing scenarios
Maintain one combined [{{Pascal}}_scenarios.md]({{Pascal}}_scenarios.md); append each endpoint's API scenarios during its EPCT QA phase. Cover happy path, validation failures, auth/forbidden, not-found, conflict/concurrency, and pagination edges.

## Notifications (email)
Drives `/taskflow:epct-dotnet`, which runs autonomously and emails the owner at task-start, plan-done, task-done, all-done, and on any blocker via `scripts/notify-email.ps1`. Run `/taskflow:init` once first.

## Status legend
✅ implemented · 🔲 stub/contract-only · ⬜ pending

> **Out of scope:** {{out-of-scope}}
````

> Do **not** generate the `{{Pascal}}_scenarios.md` file here — it is created and appended during each task's EPCT QA phase, after the work is done.

**`endpoints/NN_<feature>.md`** (per task):
````markdown
# Task {{N}} — {{Feature / Endpoint}}

- **Route:** `{{METHOD}} {{/api/<module>/path/{id}}}`
- **Auth:** {{roles/policy}}
- **Status:** {{✅ | 🔲 | ⬜}}

## Purpose
{{what this endpoint/feature does}}

## Request
- DTO: `{{RequestDto}}` (fields + types)
- Validation: {{rules → 400 on failure}}

## Response
- DTO: `{{ResponseDto}}`
```json
{{sample 2xx response, real from the contract or a TBD placeholder}}
```

## Business rules / data
- {{rules, authorization/ownership checks, DB reads/writes, side effects}}

## Errors
- `{{400 validation · 401 · 403 · 404 · 409 · 422}}` (ProblemDetails)

## Notes
- {{idempotency, pagination, transactions, gotchas}}
````

**`{{Pascal}}Tasks.csv`:** `#,Feature,Method+Route,Auth,Status` rows (opens in Excel).

### ▶ Types 2 & 3 — .NET UI pages (HTML-only / Frontend)

Same structure as above, but the per-task unit is a **page/view**, and tasks live under `pages/`.

**`README.md`**
````markdown
# {{Module}} UI — Page-wise Task Pack

Page-by-page breakdown for the **{{Module}}** {{"server-rendered (Razor Pages/MVC)" for HTML-only | "UI (Razor/MVC/Blazor) that calls the API" for Frontend}}. Each page is a task with its own context file under `pages/`.

- **Design (source of truth):** {{Figma URL or "TBD"}}
- **API it consumes:** {{API doc path or "n/a for HTML-only forms" or "TBD"}}

## Module & solution structure
Add the **`{{Pascal}}`** UI mirroring the solution's existing conventions — {{Razor Pages `Pages/` + PageModels | MVC Controllers + Views + ViewModels | Blazor components}}, shared layout/partials, and DI registration. Don't invent a new structure.

## Build order
| # | Page / View | Route | Figma | API it calls | Status |
|---|-------------|-------|-------|--------------|--------|
{{one row per page task}}

## Shared conventions (apply to every page)
- **Routing/navigation:** consistent routes; a working link/back path between pages.
- **Data:** {{HTML-only: bind via PageModel/ViewModel, forms POST back with anti-forgery token | Frontend: call the API via a typed HttpClient, handle loading/empty/error states}}.
- **Validation:** server-side model validation (+ client hints); show field errors; never trust client input.
- **Rendering:** null-safe (guards, placeholders, empty states); consistent date/number/money formatting.
- **Security:** authorize each page/action (`[Authorize]`/policies); anti-forgery on POST; no secrets in markup; encode output (no XSS).
- **Accessibility/consistency:** reuse the shared layout, partials/components, and styles; no one-off patterns.

## Testing scenarios
Maintain one combined [{{Pascal}}_scenarios.md]({{Pascal}}_scenarios.md); append each page's scenarios during its EPCT QA phase. Cover happy path, validation errors, empty/no-data, unauthorized, and navigation.

## Notifications (email)
Drives `/taskflow:epct-dotnet`, which runs autonomously and emails the owner at task-start, plan-done, task-done, all-done, and on any blocker via `scripts/notify-email.ps1`. Run `/taskflow:init` once first.

## Status legend
✅ implemented · 🔲 stub/markup-only · ⬜ pending

> **Out of scope:** {{out-of-scope}}
````

**`pages/NN_<page>.md`** (per task):
````markdown
# Task {{N}} — {{Page / View}}

- **Route:** `{{/module/path}}`
- **Type:** {{Razor Page | MVC View | Blazor component}}
- **Auth:** {{roles/policy or "anonymous"}}
- **Status:** {{✅ | 🔲 | ⬜}}

## Purpose
{{what this page shows / lets the user do}}

## UI elements (from Figma / description)
- {{fields, buttons, tables, states — loading/empty/error}}

## Data & actions
- {{HTML-only: PageModel/ViewModel properties + handlers (OnGet/OnPost) | Frontend: the API endpoints this page calls, with request/response shape}}
- Validation rules → shown errors.

## Navigation
| From | To |
|------|----|
{{navigation rows}}

## Notes
- {{gotchas, partials/components reused, permissions}}
````

**`{{Pascal}}Tasks.csv`:** `#,Page,Route,Figma,API,Status` rows (opens in Excel).

### ▶ Type 5 — .NET Frontend + Backend (full-stack)

Generate **both** folders in the one pack:
- `endpoints/` from the **.NET Backend** template, and
- `pages/` from the **.NET UI pages** template.

Use a **single `README.md`** whose Build order lists all tasks in dependency order — each API endpoint **before** the page that consumes it. One combined `{{Pascal}}Tasks.csv` may include both (add a `Kind` column: `endpoint`/`page`) or write two CSVs; prefer one CSV with a `Kind` column.

> For every .NET type (2–5): do **not** generate the `{{Pascal}}_scenarios.md` here — it's created during each task's EPCT QA phase.

---

## Phase 4 — Ensure email setup
If the project has no `scripts/notify-email.ps1`, run **`/taskflow:init`** first. Otherwise skip.

---

## Phase 5 — Finish and hand off (do NOT auto-start the build)

**Stop here. Generating the task pack and building it are two separate steps.** Do **not** invoke the EPCT automatically. Print a short summary and the exact command the user can run when they're ready:

- Summary: folder path (`<kebab-name>-tasks/`), **project type** (1–5), what's inside (`screens/` / `pages/` / `endpoints/` — or both), and task count (Task 1 → N).
- Then tell the user: *"The task pack is ready. When you want to start building, run the command below — the build runs autonomously and emails you at task-start, plan-done, task-done, and all-done (stopping only for a blocker)."*

**Give the user the command that matches their project type** (build engine: type 1 → `/taskflow:epct-rn`; types 2–5 → `/taskflow:epct-dotnet`):

- **Type 1 — React Native:** `/taskflow:epct-rn Build the complete {{Module}} module from <kebab-name>-tasks/README.md — one task at a time (Task 1 → N), following the README + each screens/*.md spec and the email notifications.`
- **Types 2 & 3 — .NET UI (HTML-only / Frontend):** `/taskflow:epct-dotnet Build the complete {{Module}} UI from <kebab-name>-tasks/README.md — one task at a time (Task 1 → N), following the README + each pages/*.md spec and the email notifications.`
- **Type 4 — .NET Backend:** `/taskflow:epct-dotnet Build the complete {{Module}} API from <kebab-name>-tasks/README.md — one task at a time (Task 1 → N), following the README + each endpoints/*.md spec and the email notifications.`
- **Type 5 — .NET Frontend + Backend:** `/taskflow:epct-dotnet Build the complete {{Module}} feature (API + UI) from <kebab-name>-tasks/README.md — one task at a time in the README's order (endpoints before the pages that use them), following each endpoints/*.md and pages/*.md spec and the email notifications.`
- **Single task:** point the matching engine at one spec file, e.g. `/taskflow:epct-rn <kebab-name>-tasks/screens/NN_<screen>.md`, or `/taskflow:epct-dotnet <kebab-name>-tasks/pages/NN_<page>.md` / `.../endpoints/NN_<feature>.md`.

Whichever EPCT the user then runs works tasks one at a time and **emails the owner at task-start, plan-done, task-done, and all-done** (no approval gates at plan or QA), only STOPPING for a genuine blocker / needed intervention (with a summary email). Reviewers: React Native → `/taskflow:rn-reviewer` + `/taskflow:platformfix-rn`; all .NET types → `/taskflow:pr-reviewer-dotnet`.

---

## Rules
- Confirm the **project type (1–5)** and the **build-order table** with the user before writing files.
- Prefer real Figma UI / real API contract; only fall back to clearly-marked `TBD` placeholders when an input is missing.
- Keep the convention blocks generic and reusable; never hard-code another project's specifics.
