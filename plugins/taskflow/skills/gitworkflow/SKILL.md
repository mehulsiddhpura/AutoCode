---
name: gitworkflow
description: Structured git workflow for React Native changes — sync main, create a feature branch, stage only app source files, confirm a staged-files table, commit with a structured message, and push.
---

# Git Workflow – React Native

---

## Step 1: Sync with main

```bash
git checkout main
git pull origin main
```

---

## Step 2: Create feature branch

```bash
git checkout -b feature/<task-name>
```

**Naming convention:**
| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<name>` | `feature/notifications-screen` |
| Bug fix | `bugfix/<name>` | `bugfix/keyboard-hides-submit` |
| Hotfix | `hotfix/<name>` | `hotfix/crash-on-order-place` |

---

## Step 3: Stage files

Stage only source files from `app/`:

```bash
git add app/
```

If `android/` or `ios/` native files were intentionally changed (e.g. manifest, Podfile, build.gradle), stage them explicitly by file path — never with `git add android/` wholesale:

```bash
git add android/app/src/main/AndroidManifest.xml
git add ios/Podfile
```

**NEVER stage:**
- `node_modules/`
- `android/build/` · `android/.gradle/` · `android/app/build/`
- `ios/build/` · `ios/Pods/` · `ios/DerivedData/`
- `*.log` · `*.lock` (unless `package-lock.json` or `yarn.lock` intentionally changed)
- `.claude/` · `CLAUDE.md`
- `_ai_context/epct/` (unless explicitly requested)
- `tmpclaude-*`

---

## Step 4: Review staged files (REQUIRED before commit)

```bash
git status
git diff --staged --stat
```

Display staged files in this format and **ask user to confirm before committing:**

```
## Files to be Committed

| # | Status   | File Path                              |
|---|----------|----------------------------------------|
| 1 | Modified | app/screens/Module/ModuleScreen.tsx    |
| 2 | New      | app/screens/Module/components/Item.tsx |
| 3 | Modified | app/store/moduleStore.tsx              |

Total: X files (Y new, Z modified)

Proceed with commit? (yes/no)
```

**Verification checklist before confirming:**
- [ ] No `node_modules/`, `android/build/`, `ios/build/`, `ios/Pods/`
- [ ] No `.claude/`, `CLAUDE.md`, `tmpclaude-*`
- [ ] No unintended native file changes
- [ ] All changed app/ files are included
- [ ] No debug/temp files

---

## Step 5: Commit

```bash
git commit -m "$(cat <<'EOF'
<type>: <short description>

Summary:
- <what was implemented>

Changes:
- <File>: <what changed>
- <File>: <what changed>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

**Commit message types:**
| Type | When |
|------|------|
| `feat` | New screen, feature, or module |
| `fix` | Bug fix |
| `refactor` | Code restructure without behaviour change |
| `style` | Styling/layout only changes |
| `perf` | Performance improvement |
| `chore` | Config, deps, or tooling change |

---

## Step 6: Push

```bash
git push -u origin feature/<task-name>
```

---

## Merge Conflict Resolution

### Most common: pull main into feature branch

```bash
# On your feature branch
git pull origin main
```

**If conflicts occur:**
```bash
git status                    # see conflicted files
# resolve each file manually — remove <<<<< ===== >>>>> markers
git add <resolved-file>
git commit -m "Merge main into feature/<task-name>"
git push
```

### Conflict resolution strategies

| Strategy | When |
|----------|------|
| Keep yours | Your change is correct |
| Keep theirs | Incoming change is correct |
| Keep both | Independent changes on different lines |
| Manual merge | Same lines changed differently — combine logic |

### Abort if needed

```bash
git merge --abort    # abort an in-progress merge
git rebase --abort   # abort an in-progress rebase
```

---

## Undo helpers

```bash
# Undo last commit — keep changes staged
git reset --soft HEAD~1

# Unstage a file
git restore --staged <file>

# Discard changes in a file
git restore <file>
```

---

## Quick reference

```bash
git checkout main && git pull origin main
git checkout -b feature/<name>

# after coding
git add app/
git status                          # review before commit
git commit -m "feat: description"
git push -u origin feature/<name>
```
