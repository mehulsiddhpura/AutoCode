---
name: epct-dotnet
description: Structured 5-phase Explore-Plan-Code-Test-QA workflow for .NET / backend features and non-trivial bug fixes, with approval and QA gates plus security, authorization, and database principles.
---

# EPCT — Standard

**Alignment Gates**
- **Gate 1 — APPROVED**: Stop after Phase 1 (Explore) and Phase 2 (Plan). Start Phase 3 (Code) only when the task owner replies **APPROVED**.
- **Gate 2 — QA PASSED**: Stop after Phase 5 (QA) and present the QA Report as the final deliverable.

**Task Inputs (from Jira/prompt) must include**
- Task ID, Outcome, Scope IN/OUT, Constraints, Definition of Done, Risks.

**Required Outputs**
- Phase 1 (Explore): files/paths to read + why; findings; unknowns & risks (mitigation).
- Phase 2 (Plan): numbered WBS + acceptance criteria; exact test commands; impact list.
- Phase 3 (Code): diffs/patches + build/test outputs + principles compliance.
- Phase 4 (Test): results & evidence; DoD check.
- Phase 5 (QA): QA Report table (PASS/FAIL per category); test matrix; code-path trace; authorization audit; principles compliance re-check.

**Artifacts**
- Save all phases to `docs/epct/{TASK_ID}.md` and link it in the PR.

---

## Development Principles (MUST FOLLOW)

### Security
- Sanitize all user text inputs before saving to database
- Validate file uploads by content (MIME type, magic bytes), not just extension
- Always filter queries by tenant/organization/user scope
- Cascade delete/archive child records when parent is deleted
- Use parameterized queries only - never concatenate user input into queries
- Never commit commented-out code that contains security-sensitive operations

### Authorization
- Verify the logged-in user owns the resource before returning data
- Add authorization checks for ALL user roles, not just one
- If user's role ID is null or missing, deny access immediately
- Log unauthorized access attempts with user context

### Database & Queries
- Load related entities in a single query, not inside loops (avoid N+1)
- Wrap multiple database writes in a transaction for atomicity
- Apply the same filters to all code paths - don't skip filters for some roles
- Use the same filtered query for count and results in pagination
- Ensure date ranges don't overlap - previous period must end before current starts

### Configuration
- Move limits (file size, timeouts, counts) to configuration - no hardcoded values
- Use enums or constants for status values, not raw strings
- Externalize allowed file types, size limits, and other settings

### Error Handling
- Handle specific error types separately (rate limit, timeout, bad request)
- If external service fails, return meaningful error and allow fallback
- Return clear error messages to users, log detailed errors for debugging
- Log all exceptions with context before handling

### Completeness
- Ensure all injected dependencies are actually used
- Map all response model properties - don't leave fields null by accident
- Apply same logic to all code paths (if/else branches, switch cases)
- Handle null cases for optional parameters before using them
- Remove dead/commented-out code completely

### Code Quality
- Remove duplicate import/using statements
- Log entry point, success, and error for important operations
- Register all new services in dependency injection container

---

## Phase 1: Explore
- Research the current codebase and relevant patterns
- Identify existing similar implementations
- Understand dependencies and constraints
- Document key findings and considerations

## Phase 2: Plan
- Design the implementation approach
- Break down into manageable tasks
- Identify potential risks and mitigation strategies
- **Review Development Principles above and note which apply to this task**
- Create a detailed execution timeline

## Phase 3: Code

**Before writing any code, verify compliance with:**
- [ ] Security: Input sanitization, file validation, tenant filtering, parameterized queries
- [ ] Authorization: Resource ownership, all roles checked, null role handling
- [ ] Database: No N+1 queries, transactions for multi-write, consistent filters
- [ ] Configuration: No hardcoded limits, use enums/constants
- [ ] Error Handling: Specific error types, meaningful messages, proper logging
- [ ] Completeness: All dependencies used, all fields mapped, null handled

**Implementation:**
- Implement the solution following our coding standards
- Write clean, maintainable, and well-documented code
- Include appropriate error handling and edge cases
- Follow our established patterns and conventions

## Phase 4: Test
- Create comprehensive unit tests
- Add integration tests where appropriate
- Test edge cases and error conditions
- Verify performance meets requirements
- **Verify all Development Principles are followed in the implementation**

## Phase 5: QA

**Claude acts as automated QA. Code is not considered done without passing ALL checks below.**

### Step 1: Self-QA Checklist

| # | Category | What to verify |
|---|----------|---------------|
| 1 | **Positive tests** | All happy-path scenarios execute correctly and return expected results |
| 2 | **Negative tests** | Invalid inputs, missing data, unauthorized access all handled gracefully |
| 3 | **Security audit** | Tenant isolation enforced, authorization roles correct, input sanitization applied, no SQL injection vectors |
| 4 | **Edge cases** | Null values, empty collections, boundary conditions (min/max), concurrent access scenarios |
| 5 | **Code-path trace** | Every if/else branch, switch case, early return, and catch block has coverage |
| 6 | **Controller validation** | Routes correct, `[Authorize]` attributes match expected roles, model validation present, correct `BaseController` response methods used |
| 7 | **Principles compliance** | Re-verify ALL Development Principles (Security, Authorization, Database, Configuration, Error Handling, Completeness, Code Quality) |
| 8 | **Build + test verification** | `dotnet build` passes with zero warnings/errors, `dotnet test` passes with zero failures |

### Step 2: Requirement Traceability

Compare Phase 2 (Plan) against Phase 3 (Code) implementation:
- [ ] Every planned WBS item has been implemented
- [ ] No unplanned changes were introduced (scope creep)
- [ ] All acceptance criteria from Phase 2 are satisfied
- [ ] All files listed in the impact list were actually modified

### Step 3: Regression Check

- Run `dotnet test` — ALL tests must pass (not just new ones)
- Verify existing functionality is not broken by the changes
- Check that modified shared utilities/helpers still work for all callers
- If any existing test was modified, justify why in the QA Report

### Step 4: Fresh-Eyes PR Review

Invoke `/taskflow:pr-reviewer` as a **separate agent** to review all changes with fresh context. This catches blind spots that the coding Claude missed. The PR reviewer must check all 8 dimensions: Correctness, Security, Performance, Database/EF Core, Design/Patterns, Code Quality, API Contract, Testing.

- If PR reviewer finds **MUST FIX** issues → fix them, re-run tests, re-run PR reviewer
- If PR reviewer finds only **SHOULD FIX** or **NICE TO HAVE** → document in QA Report, proceed

### Step 5: Definition of Done (DoD) Sign-off

Verify against the task's Definition of Done from Phase 2:
- [ ] All DoD criteria are met
- [ ] Unit tests cover all new code paths
- [ ] No TODO/FIXME/HACK comments left in new code
- [ ] No commented-out code left behind
- [ ] All new services registered in DI container

### QA Process Summary
1. Run `dotnet build --no-restore` — must succeed
2. Run `dotnet test --no-build` — ALL tests must pass with zero failures (regression check)
3. Trace every code path in new/modified files — document branch coverage
4. Audit authorization attributes against CLAUDE.md role definitions
5. Verify tenant isolation on all database queries
6. Check for OWASP Top 10 vulnerabilities in new code
7. Validate all edge cases are handled (nulls, empty, boundaries)
8. Re-check Development Principles compliance checklist
9. Compare implementation against Phase 2 plan — verify all items implemented, no scope drift
10. Run `/taskflow:pr-reviewer` for fresh-eyes review — fix any MUST FIX issues
11. Verify all Definition of Done criteria are met

### QA Report (Required Output)

Present a table:

| Category | Status | Evidence/Notes |
|----------|--------|---------------|
| Positive tests | PASS/FAIL | ... |
| Negative tests | PASS/FAIL | ... |
| Security audit | PASS/FAIL | ... |
| Edge cases | PASS/FAIL | ... |
| Code-path trace | PASS/FAIL | ... |
| Controller validation | PASS/FAIL | ... |
| Principles compliance | PASS/FAIL | ... |
| Build + test (all) | PASS/FAIL | ... |
| Requirement traceability | PASS/FAIL | All planned items implemented, no scope drift |
| Regression check | PASS/FAIL | All existing tests pass, no breakage |
| PR review (fresh eyes) | PASS/FAIL | No MUST FIX issues remaining |
| DoD sign-off | PASS/FAIL | All Definition of Done criteria met |

**All 12 categories must show PASS to proceed.**

### Gate: **QA PASSED**
Stop and present the QA Report to the task owner as the final deliverable.

Provide detailed output for each phase before proceeding to the next.
