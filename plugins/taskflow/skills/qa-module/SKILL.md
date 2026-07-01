---
name: qa-module
description: Full automated QA pipeline for any React Native module — discover files, write/run Jest service/ViewModel/component tests, run device verification, and produce a QA report.
---

You are running the full QA automation pipeline for the module: **$ARGUMENTS**

Execute all phases in order WITHOUT pausing for confirmation between steps. Fix any errors you encounter inline.

---

## Phase 1 — Discover & Explore the Module

### Step 1A — Find the files

The folder name may not match the module name exactly. Search broadly:

1. **Screens** — try `app/screens/$ARGUMENTS/**/*.tsx` first. If that returns nothing, run `Glob app/screens/**/*.tsx` and pick every file whose path or name contains `$ARGUMENTS` (case-insensitive). Also check common folder aliases (e.g. module "EMS" → folder `Expense`, module "CMS" → folder `Canteen`).
2. **ViewModels** — `Glob app/viewModels/**/*.tsx` then filter filenames containing `$ARGUMENTS`.
3. **Services** — `Glob app/services/**/*.tsx` then filter filenames containing `$ARGUMENTS`.
4. **Models** — `Glob app/models/**/*.tsx` then filter for `$ARGUMENTS`.

> After discovery, print the resolved paths before continuing:
> ```
> Screens folder : app/screens/<resolved>/
> ViewModels     : app/viewModels/<file>.tsx  (may be multiple)
> Services       : app/services/<file>.tsx    (may be multiple)
> Models         : app/models/<resolved>/     (if any)
> ```

### Step 1B — Read and build inventory

Read every discovered file. From what you read, build this inventory:

**Services inventory** — for each service file:
- Every exported function: name, HTTP verb, endpoint URL substring, request body type, return type

**ViewModel inventory** — for each ViewModel/hook file:
- Hook export name
- Every value it returns: state names, handler function names, computed values, loading/error flags
- Which service functions it calls and under what conditions

**Components inventory** — for each file in the `components/` subfolder under the screens folder:
- Component name, its props interface, which props are required vs optional

---

## Phase 2 — Write Jest Test Files

Use the inventory from Phase 1. Do NOT use VMS-specific names — use the actual names found.

### Step 2.0 — Check for existing tests FIRST (skip writing if present)

Before writing ANY test file, check whether it already exists. For each target path below (File A, B, C), `Glob` / check the path:

- **If the test file already exists** → DO NOT write, overwrite, or modify it. Treat it as already done. Just run it in Phase 3 and report its results. Print: `EXISTING — skipped writing: <path>`.
- **If the test file does NOT exist** → write it per the rules below.

Resolve existing files broadly — a file may exist under a slightly different name (e.g. `VMSService.test.ts` vs `vmsService.test.ts`, or covering the same service/viewModel/component). Run `Glob app/**/__tests__/**/*.test.{ts,tsx}` and match any existing test whose name or imports clearly target the same service/ViewModel/component before deciding it is missing. When in doubt that an existing file covers the unit, prefer running the existing test over writing a new one.

Print a coverage table before writing anything:

```
Unit                         | Existing test?     | Action
<ServiceFile>                | yes <path> / no    | run / write
<ViewModelFile>              | yes <path> / no    | run / write
<ComponentName>              | yes <path> / no    | run / write
```

Only write files marked `write`. Everything marked `run` is left untouched and simply executed in Phase 3.

### File A — Service Tests
**Path:** `app/services/__tests__/<ServiceFileName>.test.ts`

One file per discovered service file.

**Mock block** — adapt the URL helper name to whatever the service actually imports from `axiosConfig`:

```typescript
const mockGet = jest.fn();
const mockPost = jest.fn();
const mockPut = jest.fn();
const mockDelete = jest.fn();

jest.mock('../axiosConfig', () => ({
  default: jest.fn(() => ({
    get: mockGet,
    post: mockPost,
    put: mockPut,
    delete: mockDelete,
  })),
  getBaseUrl: jest.fn().mockResolvedValue('http://test.url'),
  getMicroUrl: jest.fn().mockResolvedValue('http://test.url'),
  getVmsUrl: jest.fn().mockResolvedValue('http://test.url'),
  getCmsUrl: jest.fn().mockResolvedValue('http://test.url'),
  getEmsUrl: jest.fn().mockResolvedValue('http://test.url'),
  getPmsUrl: jest.fn().mockResolvedValue('http://test.url'),
}));
```

**For EVERY exported function** found in inventory, write exactly two tests:

✅ **Positive** — mock the correct axios method to resolve with `{ data: <valid response shape matching the actual return type> }`. Assert the function returns the expected value and that the correct axios method was called with a URL containing the expected endpoint substring.

❌ **Negative** — mock axios to reject with `new Error('Network error')`. Assert the function's promise rejects.

---

### File B — ViewModel Tests
**Path:** `app/viewModels/__tests__/<ViewModelFileName>.test.tsx`

One file per discovered ViewModel. If the module has two ViewModels (e.g. ExpenseViewModel + TripViewModel), create two files.

**Standard mock block:**

```typescript
import { renderHook, act, waitFor } from '@testing-library/react-native';
import { <HookName> } from '../../viewModels/<ViewModelFile>';
import * as Service from '../../services/<ServiceFile>';

const mockNavigate = jest.fn();
const mockGoBack = jest.fn();
const mockShowSnackbar = jest.fn();

jest.mock('@react-navigation/native', () => ({
  useNavigation: () => ({ navigate: mockNavigate, goBack: mockGoBack }),
  useRoute: () => ({ params: {} }),
}));

jest.mock('../../utils/LocalPreferencesUtil', () => ({
  default: {
    getItem: jest.fn().mockResolvedValue('101'),
    EMP_ID: 'EmpId',
  },
}));

jest.mock('../../utils/errorHandler', () => ({
  showSnackbar: (...args: any[]) => mockShowSnackbar(...args),
  handleError: jest.fn((e: any) => e),
}));

jest.mock('../../services/<ServiceFile>');
```

**Standard beforeEach** — set default happy-path mocks for the primary list-loading service function (use the actual name from inventory):

```typescript
beforeEach(() => {
  jest.clearAllMocks();
  (<ServiceFunction> as jest.Mock).mockResolvedValue({
    success: true,
    data: [<minimalMockItem>],
    totalRecords: 1,
  });
});
```

**Render pattern:**
```typescript
const { result } = renderHook(() => <HookName>());
await waitFor(() => expect(result.current.<loadingFlag>).toBe(false));
```

**Tests to write — derive from the inventory, cover each of these categories:**

| Category | What to test |
|---|---|
| **Initial load** | Primary list populates; loading flag goes false; error snackbar NOT called on success |
| **Pagination** | `loadMore` / `onLoadMore` appends items; skips when all loaded; skips when already loading |
| **Refresh** | `onRefresh` resets to page 1 and replaces list (does not append) |
| **Search** | `onSearch` / search handler updates search state and triggers reload |
| **Filter** | `applyFilters` sets filter-active flag; `clearFilters` / `resetFilters` clears it |
| **Action — primary** | The main action handler (approve/submit/accept/save) opens confirmation state; success path calls service, shows snackbar, closes modal/state |
| **Action — secondary** | The secondary action handler (reject/decline/delete/cancel) validates required inputs; success path works correctly |
| **Navigation** | Navigate-to-detail (or equivalent) calls `mockNavigate` with correct screen name and params |
| **API error — list** | Service rejects → snackbar called, loading false, list unchanged |
| **API error — action** | Action service rejects → snackbar called, action-loading false, modal/state closed |
| **Guard conditions** | Action with null selected item → service NOT called; loadMore when complete → service NOT called |
| **success=false response** | Service resolves but `success: false` → list not updated, snackbar called |

Write one `it(...)` block per row above. Use the actual state/handler names from the inventory.

---

### File C — Component Tests
**Path:** `app/screens/<ScreensFolder>/components/__tests__/<ComponentName>.test.tsx`

One file per component found in the `components/` folder.

```typescript
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { <ComponentName> } from '../<ComponentName>';
```

Write these for every component:

✅ `renders without crash` — `render(<Component {...minimalRequiredProps} />)` does not throw

✅ `displays correct prop data` — query by the label/name/title prop value, assert it is found in the rendered output

✅ `action callbacks fire` — `fireEvent.press(...)` on each button/touchable → assert the correct callback prop was called with the expected argument

✅ `status-based rendering` — if the component has a status prop, render once per status value and assert the correct badge label or color is shown

❌ `optional props omitted` — render with all optional props excluded → does not throw

---

## Phase 3 — Run Jest

Run ALL test files for the module — both pre-existing ones (left untouched in Step 2.0) and any newly written ones.

```bash
npx jest --testPathPattern="$ARGUMENTS" --verbose --forceExit 2>&1
```

If the pattern matches too few files (e.g. module name is "EMS" but files are named "Expense"), also run:

```bash
npx jest --testPathPattern="(Expense|Trip|<other resolved names>)" --verbose --forceExit 2>&1
```

Read the full output.

- All tests pass → proceed to Phase 4.
- Tests fail → read the exact error, fix the mock or assertion, re-run. Repeat until all pass. If a test cannot pass due to an unmockable native module, document it and skip it — do not delete it.

Report the pass/fail count before moving on.

---

## Phase 4 — Device Verification via /verify

**Find the scenario file** — check `_ai_context/qa/` for a file related to this module:

1. Try `_ai_context/qa/$ARGUMENTS_scenarios.md` (exact match)
2. If not found, `Glob _ai_context/qa/*.md` and pick the file whose name best matches the module (e.g. "EMS" → `Expense_scenarios.md`)
3. Read the file.

- **File found** → use those scenarios exactly as written. Follow every step including setup and filter configuration before starting assertions. For steps marked `[MANAGER]` or 🔐, pause and list them as manual prerequisites, then continue with remaining ✅ steps.
- **File not found** → use the generic checklist below.

**Generic checklist (fallback only):**

Invoke the `/verify` skill with this instruction:

> "Test the **$ARGUMENTS** module on the connected device end to end:
> 1. Navigate to the $ARGUMENTS main screen — confirm it loads without crash or error snackbar
> 2. Verify the list renders items with correct text (name, date, status badge)
> 3. Type in the search bar — confirm results filter as you type
> 4. Open the filter panel if present — apply a filter, confirm list updates, then Reset
> 5. Tap a list item — confirm the detail screen opens showing correct data
> 6. Test all action buttons (approve / reject / submit / delete or equivalent) — confirm success snackbar and list update
> 7. Pull down to refresh — confirm the list reloads from page 1
> 8. Scroll to the bottom — confirm pagination loads the next page
> 9. Press back — confirm return navigation works and filter state is preserved
> 10. Note any crash, missing snackbar, incorrect color, or layout issue"

---

## Phase 5 — QA Report

Print this report after all phases complete. Fill in actual numbers and PASS/FAIL:

```
╔══════════════════════════════════════════════════╗
║  QA REPORT — $ARGUMENTS Module                   ║
╠══════════════════════════════════════════════════╣
║  JEST RESULTS                                    ║
║  ─────────────────────────────────────────────── ║
║  Service tests    :  X / Y passed                ║
║  ViewModel tests  :  X / Y passed                ║
║  Component tests  :  X / Y passed  (N files)     ║
║  Total            :  X / Y passed                ║
║  (existing reused : N files | newly written : M) ║
╠══════════════════════════════════════════════════╣
║  DEVICE VERIFICATION                             ║
║  ─────────────────────────────────────────────── ║
║  List loads           : PASS / FAIL              ║
║  Search               : PASS / FAIL              ║
║  Filter + Reset       : PASS / FAIL / N/A        ║
║  Pagination           : PASS / FAIL / N/A        ║
║  Detail screen        : PASS / FAIL              ║
║  Actions              : PASS / FAIL              ║
║  Pull-to-refresh      : PASS / FAIL              ║
║  Back navigation      : PASS / FAIL              ║
╠══════════════════════════════════════════════════╣
║  ISSUES FOUND                                    ║
║  ─────────────────────────────────────────────── ║
║  [list each failing test or device bug found]    ║
╚══════════════════════════════════════════════════╝
```

Save the report to `_ai_context/epct/QA_REPORT_$ARGUMENTS.md` after printing it.
