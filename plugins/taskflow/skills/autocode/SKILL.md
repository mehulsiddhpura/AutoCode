---
name: autocode
description: Turn a PRD (+ Figma for React Native, or an API/contract for .NET) into an EPCT-ready task pack and auto-start the autonomous build (email notifications, no approval gates). Works for BOTH stacks — React Native (mobile UI) and .NET (backend API). Use when the user wants to scaffold a new module/feature and build it task-by-task.
---

# autocode — PRD → task pack → auto-build (React Native OR .NET)

You are scaffolding a complete, accurate task pack for a new module and then handing it to the right EPCT flow. `$ARGUMENTS` is the module display name (e.g. "Payroll"). This skill supports two **tracks** — pick the right one first, then everything downstream follows it:

| Track | Generate | Auto-chain build | Reviewers used by that EPCT |
|---|---|---|---|
| **React Native (RN)** | screen-by-screen pack (Figma-driven UI) | `/taskflow:epct` | `/taskflow:rnreviewer`, `/taskflow:platformfix`, `/taskflow:qa-module` |
| **.NET** | endpoint/feature pack (API-driven) | `/taskflow:epct-dotnet` | `/taskflow:pr-reviewer` |

Work the phases in order. Ask only for inputs you don't already have.

---

## Phase 0 — Pick the track + gather inputs

1. **Track (ask first, via AskUserQuestion):** **React Native** or **.NET**? This decides the template, the per-task unit (screen vs endpoint), and which EPCT runs.
2. **Module name** — display name → derive `kebab-name` (folder = `kebab-name-tasks/`), `PascalName`, `lowercamel`.
3. **PRD** — file path to read, or pasted text. (Required for both tracks.)
4. **Track-specific source:**
   - **RN:** Figma file URL/key + entry node id (the frame containing the screens). Strongly recommended.
   - **.NET:** API/contract source — an OpenAPI/Swagger file, an endpoint list, or an API-spec doc (path or pasted). Strongly recommended. (Figma optional — only if the .NET work is paired with a UI.)
5. **Optional API contract doc** (either track) — if given, read it for REAL endpoints + request/response samples; else scaffold `TBD — confirm with API doc` placeholders.
6. **Stack specifics:**
   - **RN:** base-URL constant name + dev URL, API base path (`/api/<module>`), entity-id source + path param, out-of-scope.
   - **.NET:** base route (`/api/<module>`), auth scheme (JWT/roles/policies), the solution's layering convention (Controller → Service → Repository, DTOs, EF Core `DbContext`), and out-of-scope.

Skip any question already answered in `$ARGUMENTS` or the user's message.

---

## Phase 1 — Read the inputs

- **PRD:** read fully; extract the feature/screen list, flows, and per-item details.
- **RN — Figma:** if the Figma MCP is connected, `get_metadata` on the entry node → child frames (one per screen); `get_design_context` per screen → UI elements/labels/colors; `download_assets` for icons. Record each screen's node id. **Fallback (MCP off):** ask for the screen list/nodes or proceed from the PRD, marking nodes `TBD`.
- **.NET — API/contract:** parse the OpenAPI/endpoint list → the set of endpoints (method, route, request/response DTO, auth, errors). If only a PRD, derive the endpoints/features from it.
- **API doc (if provided):** map each unit → endpoints + sample request/response + error codes.

---

## Phase 2 — Derive the build order

Produce an ordered task list. **RN:** one task per **screen** (Task 1 = the entry point/dashboard tile). **.NET:** one task per **endpoint or cohesive feature** (Task 1 = the foundational/CRUD-create or the read used by others). For each task capture its identity (screen name + Figma node, OR method+route), endpoint count, status (`✅ done` / `🔲 app-only`/`stub` / `⬜ pending`), and dependencies/navigation.

Show the user the derived build-order table and let them correct it **before** writing files.

---

## Phase 3 — Generate the task pack

Create `<kebab-name>-tasks/` in the current project. **Use the template for the chosen track.** Keep the convention blocks generic — only fill the parameterized values.

### ▶ If track = React Native

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
Drives `/taskflow:epct`, which runs autonomously and emails the owner at task-start, plan-done, task-done, all-done, and on any blocker via `scripts/notify-email.ps1`. Run `/taskflow:init` once first.

## Status legend
✅ API done · 🔲 app-side only · ⬜ pending

> **Out of scope:** {{out-of-scope}}
````

**`screens/NN_<screen>.md`** (per task): `# Task N — <Screen>`; Figma node / Status / Endpoints; `## Purpose`; `## UI elements (from Figma)`; `## Navigation` (From/To); per-endpoint blocks (`METHOD /api/<module>/path/{id}` + param table + `### Sample response` JSON + `### Errors` + `### Field notes`); `## Notes`.

**`{{Pascal}}Tasks.csv`:** `#,Screen,Figma,Endpoints,Status` rows (opens in Excel).

> Do **not** generate the `{{Pascal}}_scenarios.md` file here — it is created and appended during each task's EPCT QA phase, after the work is done.

### ▶ If track = .NET

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

---

## Phase 4 — Ensure email setup
If the project has no `scripts/notify-email.ps1`, run **`/taskflow:init`** first. Otherwise skip.

---

## Phase 5 — Auto-chain into the right EPCT
Print a short summary (folder path + task count + track), then immediately invoke:
- **RN:** `/taskflow:epct` → *"Build the complete {{Module}} module from `<kebab-name>-tasks/README.md` — one task at a time (Task 1 → N), following the README + each `screens/*.md` spec and the email notifications."*
- **.NET:** `/taskflow:epct-dotnet` → *"Build the complete {{Module}} API from `<kebab-name>-tasks/README.md` — one task at a time (Task 1 → N), following the README + each `endpoints/*.md` spec and the email notifications."*

The chosen EPCT runs its **autonomous flow** — it works tasks one at a time and **emails the owner at task-start, plan-done, task-done, and all-done** (no approval gates at plan or QA), only STOPPING for a genuine blocker / needed intervention (with a summary email). It uses its track's reviewers (RN: `/taskflow:rnreviewer` + `/taskflow:platformfix`; .NET: `/taskflow:pr-reviewer`).

---

## Rules
- Confirm the **track** and the **build-order table** with the user before writing files.
- Prefer real Figma UI / real API contract; only fall back to clearly-marked `TBD` placeholders when an input is missing.
- Keep the convention blocks generic and reusable; never hard-code another project's specifics.
