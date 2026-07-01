---
name: epct
description: Structured 6-phase Explore-Plan-Code-Review-QA-Commit workflow for React Native features and non-trivial bug fixes, with approval and QA gates.
---

# EPCT – React Native

**Alignment Gates**
- **Gate 1 – APPROVED**: Stop after Phase 1 (Explore) and Phase 2 (Plan). Start Phase 3 (Code) only when the task owner replies **APPROVED**.
- **Gate 2 – QA PASSED**: Stop after Phase 5 (QA) and present the QA Report. Start Phase 6 (Commit) only when the task owner replies **QA PASSED**.

**Task Inputs must include**
- Task ID, Outcome, Scope IN/OUT, Constraints, Definition of Done, Risks.

**Required Outputs**
- Phase 1 (Explore): files/paths read + why; findings; unknowns & risks.
- Phase 2 (Plan): numbered WBS + acceptance criteria; exact test commands; impact list.
- Phase 3 (Code): diffs + build/test outputs + principles compliance checklist.
- Phase 4 (Test): results & evidence; DoD check.
- Phase 5 (QA): QA Report table (PASS/FAIL per category); platform test matrix; principles re-check.

**Artifacts**
- Save all phases to `_ai_context/epct/{TASK_ID}.md`.

---

## Development Principles (MUST FOLLOW)

### Platform
- Test every change on BOTH iOS and Android before marking complete
- Use `Platform.OS === 'ios'` / `Platform.select()` for platform divergence — never guess
- Run `/taskflow:platformfix` when implementing keyboard, modals, shadows, safe area, back button, or status bar

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
- **STOP — wait for APPROVED before proceeding to Phase 3**

## Phase 3: Code

**Before writing any code, verify compliance with:**
- [ ] Platform: Will this work on both iOS and Android? → open `/taskflow:platformfix` now if the task touches keyboard, modals, shadows, safe area, back button, or status bar
- [ ] Styling: scale()/verticalScale() used, StyleSheet.create, COLORS constants — no raw pixels or hex
- [ ] Performance: React.memo on list items, useCallback on handlers, useMemo on derived values, minimal Zustand slice
- [ ] Navigation: New screens registered in types.tsx and RootNavigator.tsx
- [ ] API: handleError in catch, showSnackbar for errors, correct URL constant used
- [ ] Security: No PII logging, no hardcoded secrets, input validated before API call
- [ ] Completeness: Null guards on API fields, useEffect cleanup present, no TODO/console.log

**While coding — use `/taskflow:platformfix` as a reference handbook:**
- Open it whenever you need the correct pattern for: KAV, modal nesting, shadows/elevation, safe area, back button, status bar, date picker, font scaling, ripple, or build cleanup
- It is NOT a step — invoke it on demand as platform questions arise during implementation

**Implementation:**
- Follow module structure: `app/screens/<Module>/` with `tabs/` and `components/` sub-folders
- Shared/cross-module UI in `app/screens/component/`
- Co-locate `StyleSheet.create` at the bottom of each file
- Bottom sheets: `forwardRef` + `{ open, close }` imperative API

## Phase 4: Review

Invoke `/taskflow:rnreviewer` as a **separate agent** to review all changed files against the full React Native + TypeScript checklist.

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
- Fix all **MUST FIX (P0)** issues immediately — re-invoke `/taskflow:rnreviewer` after fixes
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
| 9 | **rnreviewer passed** | No MUST FIX issues remain from Phase 4 review |
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

### Step 4: Fresh-Eyes `/taskflow:rnreviewer`
If Phase 4 review was done by the same agent that wrote the code, invoke `/taskflow:rnreviewer` again as a **separate fresh-context agent** to catch blind spots.
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

**All 12 categories must show PASS to proceed.**

### Gate: **QA PASSED**
Stop and present the QA Report to the task owner. Only proceed to Phase 6 (Commit) when the task owner replies **QA PASSED**.

---

## Phase 6: Commit

### ⛔ Gate: COMMIT APPROVED
**STOP. Do NOT run any git command until the user explicitly approves.**
Show a summary of all files changed during this task and wait.
Only proceed when the user replies **COMMIT**, **YES**, or **APPROVED**.

Invoke `/taskflow:gitworkflow` to execute the full git commit process.

The workflow will:
1. Sync with `main` branch
2. Create a `feature/<task-name>` branch
3. Stage only `app/` source files (and any intentionally changed native files)
4. Display a staged files table — **wait for user confirmation before committing**
5. Commit with a structured message including Co-Authored-By
6. Push to origin

**NEVER stage:** `node_modules/`, `android/build/`, `ios/build/`, `ios/Pods/`, `.claude/`, `CLAUDE.md`, `_ai_context/epct/`, `tmpclaude-*`
