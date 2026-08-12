---
name: arc-package-validator
description: Validate Swift Packages against ARC Labs Studio standards defined in ARCKnowledge. Use when checking package compliance, auditing structure, reviewing before release, or verifying ARCDevTools integration. Triggers on requests like "validate package", "check ARC standards", "is this package ready", "audit ARCPackage", "package compliance check", "review package structure".
allowed-tools: Read, Grep, Glob, Bash
---

# ARC Package Validator

Validates Swift Packages against ARC Labs Studio standards defined in ARCKnowledge.

## Quick Start

**Validate current package:**
```bash
swift .claude/skills/arc-package-validator/scripts/validate.swift .
```

**Validate with automatic fixes:**
```bash
swift .claude/skills/arc-package-validator/scripts/validate.swift . --fix
```

**Validate specific package:**
```bash
swift .claude/skills/arc-package-validator/scripts/validate.swift /path/to/ARCPackageName
```

Or simply ask: "Validate this package against ARC standards" and I'll run the checks automatically.

## Validation Categories

### 📁 Structure (from package-structure.md)
- `Package.swift` with Swift 6.0 and iOS 17+
- `README.md` following ARC Labs template
- `LICENSE` (MIT)
- `CHANGELOG.md` (Keep a Changelog format)
- `Sources/PackageName/` directory
- `Tests/PackageNameTests/` directory
- `Documentation.docc/` catalog

### ⚙️ Configuration (from arcdevtools.md)
- ARCDevTools as git submodule
- `.swiftlint.yml` present
- `.swiftformat` present
- `.github/workflows/` with CI

### 📖 Documentation (from readme-standards.md)
- Badges: Swift, Platforms, License, Version
- Required sections: Overview, Requirements, Installation, Usage
- DocC with package overview

### 🧹 Code Quality
- SwiftLint passes without errors
- SwiftFormat check passes
- Swift 6 strict concurrency compliance

## Severity Levels

| Level | Icon | Meaning | Action |
|-------|------|---------|--------|
| Error | 🔴 | Blocks release | Must fix before merge to main |
| Warning | 🟡 | Should fix | Fix before next release |
| Info | 🔵 | Suggestion | Optional improvement |

## Fix Mode

The `--fix` flag applies safe automatic fixes:

**Safe fixes (applied automatically):**
- Create missing directories (Documentation.docc/, .github/workflows/)
- Copy template files from ARCDevTools
- Create CHANGELOG.md template
- Initialize empty DocC catalog

**Manual fixes (reported only):**
- Package.swift modifications
- README content changes
- Existing file modifications

## Output

The validator generates a Markdown report with:
- Overall compliance score (percentage)
- Status indicator (✅ Pass / ⚠️ Warnings / ❌ Errors)
- Detailed list of passed checks
- Failed checks with specific fix instructions
- Commands to resolve each issue

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed (or only warnings/info) |
| 1 | Has blocking errors (🔴) |

## Reference

For detailed standards and checklist, see [references/checklist.md](references/checklist.md).

For ARCKnowledge documentation:
- [package-structure.md](https://github.com/arclabs-studio/ARCKnowledge/blob/main/Quality/package-structure.md)
- [readme-standards.md](https://github.com/arclabs-studio/ARCKnowledge/blob/main/Quality/readme-standards.md)
- [arcdevtools.md](https://github.com/arclabs-studio/ARCKnowledge/blob/main/Tools/arcdevtools.md)
