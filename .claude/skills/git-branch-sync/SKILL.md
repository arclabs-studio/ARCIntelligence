---
name: git-branch-sync
description: |
  Synchronize Git branches to the exact same commit point. Use when syncing
  develop with main after a release, or when asked to "sync branches",
  "llevar al mismo punto", or "synchronize develop with main". CRITICAL:
  Uses git reset --hard, NOT merge, to ensure branches point to identical commits.
---

# Git Branch Sync

Synchronizes Git branches to the exact same commit point using `git reset --hard`.

## When to Use This Skill

Use this skill when:
- **After creating a release tag** on `main`
- **Syncing `develop` with `main`** after merging a release
- **Any request to sync/synchronize branches** to the same point
- **Phrases like**: "sync branches", "llevar al mismo punto", "synchronize develop"

## Critical Rule

**NEVER use `git merge`** when syncing branches to the same point.

| Wrong | Right |
|-------|-------|
| `git merge main` | `git reset --hard main` |
| Creates extra commit | Same commit SHA |

## Standard Process

### 1. Sync develop with main (most common)

```bash
# Checkout develop
git checkout develop

# Reset to main (HARD reset, not merge!)
git reset --hard main

# Force push (required after reset)
git push origin develop --force

# Verify both branches show same commit
git log --oneline -1 main && git log --oneline -1 develop
```

### 2. One-liner version

```bash
git checkout develop && git reset --hard main && git push origin develop --force
```

### 3. Verify success

Both branches MUST show the **same commit SHA**:

```
ab878f5 feat: add new feature
ab878f5 feat: add new feature
```

If SHAs differ, the sync failed.

## Complete Workflow After Release

When releasing a new version:

```bash
# 1. Ensure on main with latest
git checkout main
git pull origin main

# 2. Create and push tag
git tag v1.2.0
git push origin v1.2.0

# 3. Sync develop to main
git checkout develop
git reset --hard main
git push origin develop --force

# 4. Verify
echo "main:" && git log --oneline -1 main
echo "develop:" && git log --oneline -1 develop
```

## Common Mistakes to Avoid

1. **Using merge instead of reset**
   - `git merge main` creates a merge commit → branches diverge
   - `git reset --hard main` makes branches identical

2. **Forgetting --force on push**
   - After `reset --hard`, history is rewritten
   - Regular `git push` will fail
   - Must use `git push --force`

3. **Not verifying the result**
   - Always check both branches show same SHA
   - If different, something went wrong

4. **Syncing wrong direction**
   - Usually sync `develop` → `main` (develop follows main)
   - Rarely sync `main` → `develop` (would lose main's state)

## Quick Reference

| Action | Command |
|--------|---------|
| Sync develop with main | `git checkout develop && git reset --hard main && git push origin develop --force` |
| Verify sync | `git log --oneline -1 main && git log --oneline -1 develop` |
| Check current branch | `git branch --show-current` |

## Related

- For Git workflow details → Use `/arc-workflow`
- For branch naming → Use `/arc-workflow`
