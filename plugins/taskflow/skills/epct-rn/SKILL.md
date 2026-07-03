---
name: epct-rn
description: Structured 5-phase Explore-Plan-Code-Review-QA workflow for React Native features and non-trivial bug fixes. Runs autonomously and emails the task owner at start, plan-done, task-done, all-done, and on blockers — no approval gates.
---

# EPCT – React Native

**Autonomous flow — notify, don't gate.** Work tasks one at a time (Task 1 → N) and run each task's phases straight through **without stopping for approval**. Email the task owner at the notification points below. The only time you STOP is a genuine **blocker** or a decision that truly requires human intervention.

**Notifications (email the task owner via `scripts/notify-email.ps1`)** — format every email per the **Development Notifications** spec in `CLAUDE.md`: a scannable subject `[<Module> · Task n/N] <Task> — <Status>` and a readable, **labelled** body (Module / Task / Status header, then the relevant sections, then a "What happens next" line). Keep it concise, specific, and jargon-free.
- **Task start** — when you begin a task. Subject status `Started`; body = 1-line what it covers + "Building now, no action needed". Then proceed.
- **Plan done** — when Phase 2 (Plan) is complete. Subject status `Plan ready`; body = **Plan summary** + **Acceptance criteria** + **Risks/notes**. **Informational only — do NOT wait for approval; continue straight to Phase 3.**
- **Task done** — when the task's QA (Phase 5) is complete. Subject status `Done`; body = **What shipped** (screens/files) + **QA result** + any deferred items.
- **All tasks done** — when the whole module/pack is finished. Subject `[<Module>] All <N> tasks complete ✅`; body = **per-task recap** + **outstanding risks**.
- **Blocker / intervention needed** — any phase, when progress is blocked or a decision only the owner can make is required. Subject status `NEEDS YOUR INPUT`; body = **What happened** + **Why** + **What I need from you** (exact). **STOP** and email this.

Email failures are non-fatal (log and continue). A real blocker still STOPS the task until the owner responds.

**Task Inputs must include**
- Task ID, Outcome, Scope IN/OUT, Constraints, Definition of Done, Risks.

**Required Outputs**
- Phase 1 (Explore): files/paths read + why; findings; unknowns & risks.
- Phase 2 (Plan): numbered WBS + acceptance criteria; exact test commands; impact list.
- Phase 3 (Code): diffs + build/test outputs + principles compliance checklist.
- Phase 4 (Review): reviewer verdict + fixes applied.
- Phase 5 (QA): QA Report table (PASS/FAIL per category); platform test matrix; principles re-check.

**Artifacts**
- Save all phases to `_ai_context/epct/{TASK_ID}.md`.

---

## Development Principles (MUST FOLLOW)

### Platform
- Test every change on BOTH iOS and Android before marking complete
- Use `Platform.OS === 'ios'` / `Platform.select()` for platform divergence — never guess
- Run `/taskflow:platformfix-rn` when implementing keyboard, modals, shadows, safe area, back button, or status bar

### Styling
- Always use `scale()` for horizontal/font sizes and `verticalScale()` for heights from `app/utils/scalingUtils.tsx`
- Always use `StyleSheet.create({})` — never inline style objects (breaks `React.memo`, creates new refs on every render)
- Import all colors from `app/styles/colors.tsx` — never hardcode hex values

### Performance
- List item components must always be `React.memo` — never pass inline lambdas or inline style arrays as props
- Screen-level event handlers use `useCallback`; expensive derived values use `useMemo`
- Extract any form field with its own `useState` into a sub-component (keeps keystroke renders local)
- Zustand: subscribe to the minimum slice (`state => state.x`); use `getState()` inside callbacks

### Navigation
- Add every new screen to both `ScreenNames` enum and `RootStackParamList` in `app/navigation/types.tsx`, then register in `RootNavigator.tsx`
- Full-screen flows must be stack screens — not `Modal` components
- Use timestamp signals (`notifyOrderPlaced()`) to trigger parent re-fetches on back navigation — not route params

### API & Error Handling
- Always call `handleError` from `app/utils/errorHandler.tsx` in every `catch` block
- Display errors with `showSnackbar(message, true)`
- Never hardcode base URLs — use URL constants from `app/utils/apiEndpoints.tsx`
- Handle null/undefined for all API response fields before rendering

### Security
- Never log authentication tokens, user PII, or session data via `console.log`
- Store sensitive data in encrypted storage (react-native-keychain), not AsyncStorage
- Validate all user inputs before sending to API

### Completeness
- Every `useEffect` that subscribes must return a cleanup/unsubscribe function
- Handle all nullable API fields with null guards before accessing nested properties
- Never leave TODO / FIXME / HACK comments in new code
- Remove all `console.log` debug statements before committing

### Code Quality
- Co-locate `StyleSheet.create` at the bottom of each file
- Module structure: `app/screens/<Module>/` with `tabs/` and `components/` sub-folders
- Shared cross-module UI goes in `app/screens/component/`
- Bottom sheets use `forwardRef` with `{ open(...), close() }` imperative API — export the ref type alongside the component

---

## Phase 1: Explore
- **Email "Task start"** — notify the owner the task is beginning (task name + what it covers), then proceed without waiting.
- Read the relevant AI context doc in `_ai_context/modules/` if one exists for the affected module
- **Review design patterns and common components in the existing feature modules in this app:**
  - Study how each module structures its screens, tabs, and module-specific components under `app/screens/<Module>/`
  - Identify shared/reusable UI and the established design patterns (headers, list rows, bottom sheets, filters, detail rows, searchable selects) used across these modules
  - Note the conventions to reuse so the new work matches the look, feel, and component contracts of the existing modules rather than introducing new one-off patterns
- Identify existing similar screens, components, and service patterns
- Understand navigation flow, state shape (Zustand store slices), and API contracts
- Document key findings, unknowns, and risks

## Phase 2: Plan
- Design the implementation approach
- Write a numbered WBS with acceptance criteria for each item
- List exact test commands
- List all files that will be modified (impact list)
- Review Development Principles above and note which apply to this task
- **Email "Plan done"** — send the plan summary + acceptance criteria + risks to the owner. This is informational; **do NOT wait for approval — continue straight to Phase 3.**

## Phase 3: Code

**Before writing any code, verify compliance with:**
- [ ] Platform: Will this work on both iOS and Android? → open `/taskflow:platformfix-rn` now if the task touches keyboard, modals, shadows, safe area, back button, or status bar
- [ ] Styling: scale()/verticalScale() used, StyleSheet.create, COLORS constants — no raw pixels or hex
- [ ] Performance: React.memo on list items, useCallback on handlers, useMemo on derived values, minimal Zustand slice
- [ ] Navigation: New screens registered in types.tsx and RootNavigator.tsx
- [ ] API: handleError in catch, showSnackbar for errors, correct URL constant used
- [ ] Security: No PII logging, no hardcoded secrets, input validated before API call
- [ ] Completeness: Null guards on API fields, useEffect cleanup present, no TODO/console.log

**While coding — use `/taskflow:platformfix-rn` as a reference handbook:**
- Open it whenever you need the correct pattern for: KAV, modal nesting, shadows/elevation, safe area, back button, status bar, date picker, font scaling, ripple, or build cleanup
- It is NOT a step — invoke it on demand as platform questions arise during implementation

**Implementation:**
- Follow module structure: `app/screens/<Module>/` with `tabs/` and `components/` sub-folders
- Shared/cross-module UI in `app/screens/component/`
- Co-locate `StyleSheet.create` at the bottom of each file
- Bottom sheets: `forwardRef` + `{ open, close }` imperative API

## Phase 4: Review

Invoke `/taskflow:rn-reviewer` as a **separate agent** to review all changed files against the full React Native + TypeScript checklist.

The reviewer checks 10 dimensions:
1. TypeScript safety (no `any`, null guards, explicit return types)
2. React & Hooks correctness (deps, cleanup, no render-time setState)
3. Performance (React.memo, useCallback, useMemo, no inline lambdas/styles as props)
4. Styling (scale/verticalScale, StyleSheet.create, COLORS constants — no raw pixels or hex)
5. Platform-specific (KAV behavior, modal nesting, shadow vs elevation, safe area)
6. Navigation (screen registration, back-nav signals, no Modal for full-screen flows)
7. State management (minimal Zustand slice, getState() in callbacks)
8. API & Error handling (handleError in catch, showSnackbar, null guards on response fields)
9. Security (no token/PII logging, secure storage, input validation)
10. Debug artifacts (no console.log, TODO, FIXME, commented-out code)

**After the review:**
- Fix all **MUST FIX (P0)** issues immediately — re-invoke `/taskflow:rn-reviewer` after fixes
- Document **SHOULD FIX (P1)** items in the QA Report if deferred
- Proceed to Phase 5 only when the reviewer verdict is **Ready to proceed** or **Proceed after SHOULD FIX items addressed**

## Phase 5: QA

**Claude acts as automated QA. No code moves to commit without passing ALL checks below.**

### Step 1: Self-QA Checklist

| # | Category | What to verify |
|---|----------|----------------|
| 1 | **Positive tests** | Happy-path renders correctly; data displays as expected |
| 2 | **Negative tests** | Empty state, network error, null fields, empty lists all handled gracefully |
| 3 | **iOS audit** | KAV behavior="padding", modals nested correctly, shadow props used, safe area handled |
| 4 | **Android audit** | KAV behavior=undefined, elevation for shadows, back button, adjustResize set |
| 5 | **Performance audit** | No inline lambdas in list item props, memo/callback/useMemo applied correctly |
| 6 | **Styling audit** | scale()/verticalScale() everywhere, StyleSheet.create only, COLORS used, no raw pixels |
| 7 | **Navigation audit** | New screens registered; back-nav side effects use signals not route params |
| 8 | **Principles compliance** | Re-verify ALL Development Principles above |
| 9 | **rn-reviewer passed** | No MUST FIX issues remain from Phase 4 review |
| 10 | **No debug artifacts** | No console.log, no TODO/FIXME, no commented-out code |

### Step 2: Requirement Traceability
- [ ] Every planned WBS item has been implemented
- [ ] No unplanned changes introduced (scope creep)
- [ ] All acceptance criteria from Phase 2 satisfied
- [ ] All impact-list files modified

### Step 3: Regression Check
- Verify existing screens not broken by shared component or store changes
- If any shared component in `app/screens/component/` was modified, trace all its callers
- If any Zustand store action was modified, verify all subscribers still behave correctly

### Step 4: Fresh-Eyes `/taskflow:rn-reviewer`
If Phase 4 review was done by the same agent that wrote the code, invoke `/taskflow:rn-reviewer` again as a **separate fresh-context agent** to catch blind spots.
- Fix any new **MUST FIX** issues, re-run reviewer
- Document **SHOULD FIX** items in the QA Report

### Step 5: Definition of Done (DoD) Sign-off
- [ ] Works correctly on both iOS and Android
- [ ] All jest tests pass with zero failures
- [ ] No inline styles, no raw pixel values, no hardcoded hex colors
- [ ] No TODO/FIXME/HACK/console.log in committed code
- [ ] New screens registered in types.tsx and RootNavigator.tsx (if applicable)
- [ ] `_ai_context/epct/{TASK_ID}.md` artifact saved

### QA Report (Required Output)

| Category | Status | Evidence/Notes |
|----------|--------|----------------|
| Positive tests | PASS/FAIL | |
| Negative tests | PASS/FAIL | |
| iOS audit | PASS/FAIL | |
| Android audit | PASS/FAIL | |
| Performance audit | PASS/FAIL | |
| Styling audit | PASS/FAIL | |
| Navigation audit | PASS/FAIL | |
| Principles compliance | PASS/FAIL | |
| Test run (jest) | PASS/FAIL | |
| Requirement traceability | PASS/FAIL | All planned items implemented, no scope drift |
| Regression check | PASS/FAIL | All existing tests pass, no breakage |
| PR review (fresh eyes) | PASS/FAIL | No MUST FIX issues remaining |

**All 12 categories must show PASS before the task is considered done.**

### Task done
Present the QA Report, then **email "Task done"** to the owner (what shipped in this task + QA verdict + any deferred SHOULD FIX items). No approval gate — move on to the next task.

If a QA category is **FAIL** and you cannot resolve it yourself, treat it as a **blocker**: STOP and email a summary of what failed and what input is needed (see the Notifications section at the top).

---

## After the last task: All tasks done
When every task in the pack is complete, **email "All tasks done"** with a per-task summary and any outstanding risks.

> **Committing is not part of this flow.** This EPCT ends at the QA Report + "Task done" email. If you want to commit/push the work, run `/taskflow:gitworkflow` separately.
