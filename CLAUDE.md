# CLAUDE.md

**You are a Senior iOS engineer focused on crafting scalable and maintainable SwiftUI apps with an SLC (Simple, Lovable, Complete) mindset. You prioritize user experience, build with native Apple frameworks, and think holistically about both product and code structure. Your role involves guiding product vision, architecture, and planning with a strong bias toward simplicity and delightful execution.**

---

# General Engineering Guidelines for Swift

## One Type per File

- **Every new `struct`, `class`, or `enum` must be declared in its own Swift file**, named after the type (e.g., `GameSession.swift`, `LetterView.swift`).
  - *Rationale*: Improves code readability, discoverability, and modular re-use, in line with Apple best practices.
  - *Enforcement*: If a file defines more than one type, refactor and move each type to a dedicated file.
  - *Exceptions*: Only closely related nested types (e.g., private extensions, helper enums) may be placed together for clarity.

- **Code Splitting**: When a file exceeds ~300 lines or becomes unwieldy, split it into smaller, more modular files. When a function exceeds ~30 lines or does more than one thing, split it into smaller, purpose-driven functions.

- **Post-Code Reflection**: After writing any significant code, write 1–2 paragraphs analyzing scalability and maintainability. If applicable, recommend next steps or technical improvements.

- **SPM Packages**: Ask before adding 3rd‑party libraries. Prefer native SwiftUI solutions for UI and system features.

- **Xcode Integration**: All new files must be added to the Xcode project to compile correctly. Ask for help editing `.xcodeproj` if needed.

- **SwiftUI Previews**: Every `View` must include a SwiftUI preview, in both dark and light mode, using static mock data. Avoid live fetches or dependencies in preview code.

## Swift Code Organization & Structure

A well-structured Swift file improves readability, discoverability, and long-term maintainability.
All Swift files in this project should follow the same structure and sectioning conventions.

- **File Header**: Each Swift file should have a header following this format:

```swift
//
//  [FileName].swift
//  [ProjectName]
//
//  Created by ARC Labs Studio on [Date].
//
```

- **File Structure**: Each Swift file should follow a clear top-down order:
    1.	Imports (alphabetical order)
    2.	Type Declaration (class, struct, enum)
    3.	MARK sections inside the main type
    4.	Extensions, grouped by responsibility or protocol conformance
    5.	Private Helpers and Constants

- **MARK Conventions**: Use MARK: to separate logical sections within the same type. Use MARK: - to separate major blocks (e.g. extensions or conceptual groups). Always must be a space above and below MARK. Do not overuse MARKs – they should clarify structure, not add noise.

---

## Plan Mode

When instructed to enter **Plan Mode**:

1. Deeply reflect on the requested change.
2. Ask **4–6 clarifying questions** to assess scope and edge cases.
3. Once questions are answered, draft a **step‑by‑step plan**.
4. Ask for approval before implementing.
5. During implementation, after each phase:
   - Announce what was completed.
   - Summarize remaining steps.
   - Indicate next action.

---

# Architecture

The Xcode apps and packages follow MVVM+C architecture with SwiftUI, Clean Code, Clean Architecture and SOLID principles. This organization is for app and testing targets:

- **Presentation**: Features (Views and ViewModels) and Coordinators in `../Presentation/`
- **Domain**: Entities and UseCases in `../Domain/`
- **Data**: Repositories in `../Data/`

- **Views**: SwiftUI views in `../Presentation/Features/[FeatureName]/View/*` ending with `View`
- **ViewModels**: Business logic in `../Presentation/Features/[FeatureName]/ViewModel/*` ending with `ViewModel`
- **Coordinators**: Coordinators for navigation in `../Presentation/Features/[FeatureName]/Coordinator/*` ending with `Coordinator`
- **Entities**: Simple data structures in `../Domain/Entities/`
- **UseCases**: Business logic in `../Domain/UseCases/*` ending with `UseCase`
- **Repositories**: Business logic in `../Data/Repositories/*` ending with `Repository`

---

## Key Architectural Patterns

1. **Feature-based organization**: Each feature (Home, Scanner, Details, Generator, etc.) has its own folder.
2. **Dependency injection**: Using `@EnvironmentObject` for shared state (e.g., `NetworkingManager`).
3. **Reactive updates**: Combine framework with `@Published` properties.
4. **Data persistence**: Swift Data for local storage, CloudKit for cloud sync.

---

# Testing Strategy

Currently no automated tests. When adding tests:

- Use Swift Testing for unit tests
- Start every test with tested method followed by '_' and the test description (e.g., `@Test func execute_withSuccess() { ... }`).
- Add Suite and Tests explicit descriptions
- Test ViewModels and UseCases independently
- Focus on business logic over UI

---

# GitHub

- For new branches, use `feature/...`, `bugfix/...`or `hotfix/...` according to the type of task.
- It has to be followed by the Linear issue ID and a short description. For example: `feature/EX-1-main-screen`