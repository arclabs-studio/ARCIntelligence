#!/usr/bin/env swift

// ARC Package Validator
// Validates Swift Packages against ARC Labs Studio standards
// Usage: swift validate.swift <package-path> [--fix] [--verbose]

import Foundation

// MARK: - Models

enum Severity: String, Comparable, CaseIterable {
    case error = "🔴"
    case warning = "🟡"
    case info = "🔵"

    var name: String {
        switch self {
        case .error: "Error"
        case .warning: "Warning"
        case .info: "Info"
        }
    }

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        let order: [Severity] = [.info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

struct ValidationResult {
    let category: String
    let name: String
    let passed: Bool
    let severity: Severity
    let message: String
    let fix: String?
    let fixCommand: String?
    let canAutoFix: Bool

    init(category: String,
         name: String,
         passed: Bool,
         severity: Severity,
         message: String,
         fix: String? = nil,
         fixCommand: String? = nil,
         canAutoFix: Bool = false) {
        self.category = category
        self.name = name
        self.passed = passed
        self.severity = severity
        self.message = message
        self.fix = fix
        self.fixCommand = fixCommand
        self.canAutoFix = canAutoFix
    }
}

struct ValidationReport {
    let packageName: String
    let packagePath: String
    let results: [ValidationResult]
    let timestamp: Date
    let fixesApplied: [String]

    var passedCount: Int {
        results.filter(\.passed).count
    }

    var failedCount: Int {
        results.filter { !$0.passed }.count
    }

    var errorCount: Int {
        results.filter { !$0.passed && $0.severity == .error }.count
    }

    var warningCount: Int {
        results.filter { !$0.passed && $0.severity == .warning }.count
    }

    var infoCount: Int {
        results.filter { !$0.passed && $0.severity == .info }.count
    }

    var score: Int {
        guard !results.isEmpty else { return 0 }
        return (passedCount * 100) / results.count
    }

    var status: String {
        if results.allSatisfy(\.passed) {
            return "✅ All checks passed"
        }
        if errorCount > 0 {
            return "❌ Has blocking errors (\(errorCount))"
        }
        if warningCount > 0 {
            return "⚠️ Has warnings (\(warningCount))"
        }
        return "💡 Has suggestions (\(infoCount))"
    }

    var hasBlockingErrors: Bool {
        errorCount > 0
    }
}

// MARK: - Shell Execution

@discardableResult func shell(_ command: String, at directory: String? = nil) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.arguments = ["-c", command]

    if let directory {
        task.currentDirectoryURL = URL(fileURLWithPath: directory)
    }

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        return ("Error: \(error.localizedDescription)", 1)
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    return (output.trimmingCharacters(in: .whitespacesAndNewlines), task.terminationStatus)
}

// MARK: - Validator

class ARCPackageValidator {
    let packagePath: URL
    let packageName: String
    let fileManager = FileManager.default
    let verbose: Bool

    private var results: [ValidationResult] = []
    private var fixesApplied: [String] = []

    init(path: String, verbose: Bool = false) throws {
        let resolvedPath: String = if path == "." {
            fileManager.currentDirectoryPath
        } else if path.hasPrefix("/") {
            path
        } else {
            fileManager.currentDirectoryPath + "/" + path
        }

        packagePath = URL(fileURLWithPath: resolvedPath).standardized
        packageName = packagePath.lastPathComponent
        self.verbose = verbose

        guard fileManager.fileExists(atPath: packagePath.path) else {
            throw ValidatorError.packageNotFound(resolvedPath)
        }

        if verbose {
            print("📦 Validating package: \(packageName)")
            print("📍 Path: \(packagePath.path)")
            print("")
        }
    }

    func validate(applyFixes: Bool = false) -> ValidationReport {
        results = []
        fixesApplied = []

        // Structure checks
        if verbose {
            print("📁 Checking structure...")
        }
        checkPackageSwift(applyFixes: applyFixes)
        checkReadme(applyFixes: applyFixes)
        checkLicense(applyFixes: applyFixes)
        checkChangelog(applyFixes: applyFixes)
        checkSourcesDirectory()
        checkTestsDirectory()
        checkDocumentation(applyFixes: applyFixes)
        checkGitignore(applyFixes: applyFixes)

        // Configuration checks
        if verbose {
            print("⚙️ Checking configuration...")
        }
        checkARCDevTools()
        checkSwiftLint(applyFixes: applyFixes)
        checkSwiftFormat(applyFixes: applyFixes)
        checkGitHubWorkflows(applyFixes: applyFixes)
        checkMakefile()

        // README content checks
        if verbose {
            print("📖 Checking README content...")
        }
        checkReadmeContent()

        // Code quality checks
        if verbose {
            print("🧹 Checking code quality...")
        }
        runSwiftLintCheck()
        runSwiftFormatCheck()
        checkSwiftBuild()

        // Test checks
        if verbose {
            print("🧪 Checking tests...")
        }
        checkTestsExist()

        return ValidationReport(packageName: packageName,
                                packagePath: packagePath.path,
                                results: results,
                                timestamp: Date(),
                                fixesApplied: fixesApplied)
    }

    // MARK: - Helper Methods

    private func fileExists(_ relativePath: String) -> Bool {
        let path = packagePath.appendingPathComponent(relativePath)
        return fileManager.fileExists(atPath: path.path)
    }

    private func directoryExists(_ relativePath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let path = packagePath.appendingPathComponent(relativePath)
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func readFile(_ relativePath: String) -> String? {
        let path = packagePath.appendingPathComponent(relativePath)
        return try? String(contentsOf: path, encoding: .utf8)
    }

    private func createDirectory(_ relativePath: String) -> Bool {
        let path = packagePath.appendingPathComponent(relativePath)
        do {
            try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }

    private func writeFile(_ relativePath: String, content: String) -> Bool {
        let path = packagePath.appendingPathComponent(relativePath)
        do {
            try content.write(to: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private func addResult(_ result: ValidationResult) {
        results.append(result)
        if verbose {
            let icon = result.passed ? "✓" : "✗"
            print("  \(icon) \(result.name): \(result.message)")
        }
    }

    // MARK: - Structure Checks

    private func checkPackageSwift(applyFixes _: Bool) {
        let category = "Structure"

        guard fileExists("Package.swift") else {
            addResult(ValidationResult(category: category,
                                       name: "Package.swift exists",
                                       passed: false,
                                       severity: .error,
                                       message: "Package.swift not found",
                                       fix: "Create Package.swift with swift-tools-version: 6.0"))
            return
        }

        guard let content = readFile("Package.swift") else {
            addResult(ValidationResult(category: category,
                                       name: "Package.swift readable",
                                       passed: false,
                                       severity: .error,
                                       message: "Cannot read Package.swift"))
            return
        }

        // Check swift-tools-version
        let hasCorrectVersion = content.contains("swift-tools-version: 6.0") ||
            content.contains("swift-tools-version:6.0")
        addResult(ValidationResult(category: category,
                                   name: "Swift tools version",
                                   passed: hasCorrectVersion,
                                   severity: .error,
                                   message: hasCorrectVersion
                                       ? "Using swift-tools-version 6.0"
                                       : "Should use swift-tools-version: 6.0",
                                   fix: hasCorrectVersion ? nil : "Update first line to: // swift-tools-version: 6.0"))

        // Check iOS platform
        let hasiOS17 = content.contains(".iOS(.v17)")
        addResult(ValidationResult(category: category,
                                   name: "iOS 17+ platform",
                                   passed: hasiOS17,
                                   severity: .error,
                                   message: hasiOS17
                                       ? "iOS 17+ platform configured"
                                       : "Missing iOS 17+ platform requirement",
                                   fix: hasiOS17
                                       ? nil
                                       : "Add platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17)]"))

        // Check strict concurrency
        let hasStrictConcurrency = content.contains("StrictConcurrency")
        addResult(ValidationResult(category: category,
                                   name: "Strict concurrency",
                                   passed: hasStrictConcurrency,
                                   severity: .warning,
                                   message: hasStrictConcurrency
                                       ? "Strict concurrency enabled"
                                       : "Strict concurrency not enabled",
                                   fix: hasStrictConcurrency
                                       ? nil
                                       : "Add swiftSettings: [.enableExperimentalFeature(\"StrictConcurrency\")]"))
    }

    private func checkReadme(applyFixes _: Bool) {
        let exists = fileExists("README.md")
        addResult(ValidationResult(category: "Structure",
                                   name: "README.md exists",
                                   passed: exists,
                                   severity: .error,
                                   message: exists ? "README.md found" : "README.md not found",
                                   fix: exists ? nil : "Create README.md following ARC Labs template"))
    }

    private func checkLicense(applyFixes _: Bool) {
        let exists = fileExists("LICENSE")
        addResult(ValidationResult(category: "Structure",
                                   name: "LICENSE exists",
                                   passed: exists,
                                   severity: .error,
                                   message: exists ? "LICENSE found" : "LICENSE not found",
                                   fix: exists ? nil : "Add MIT LICENSE file"))
    }

    private func checkChangelog(applyFixes: Bool) {
        let exists = fileExists("CHANGELOG.md")

        if !exists, applyFixes {
            let template = """
            # Changelog

            All notable changes to this project will be documented in this file.

            The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
            and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

            ## [Unreleased]

            ### Added
            - Initial release

            """
            if writeFile("CHANGELOG.md", content: template) {
                fixesApplied.append("Created CHANGELOG.md")
                addResult(ValidationResult(category: "Structure",
                                           name: "CHANGELOG.md exists",
                                           passed: true,
                                           severity: .warning,
                                           message: "CHANGELOG.md created (auto-fix)"))
                return
            }
        }

        addResult(ValidationResult(category: "Structure",
                                   name: "CHANGELOG.md exists",
                                   passed: exists,
                                   severity: .warning,
                                   message: exists ? "CHANGELOG.md found" : "CHANGELOG.md not found",
                                   fix: exists ? nil : "Create CHANGELOG.md following Keep a Changelog format",
                                   canAutoFix: true))
    }

    private func checkSourcesDirectory() {
        let path = "Sources/\(packageName)"
        let exists = directoryExists(path)

        addResult(ValidationResult(category: "Structure",
                                   name: "Sources directory",
                                   passed: exists,
                                   severity: .error,
                                   message: exists
                                       ? "Sources/\(packageName)/ found"
                                       : "Sources/\(packageName)/ not found",
                                   fix: exists ? nil : "Create Sources/\(packageName)/ directory"))
    }

    private func checkTestsDirectory() {
        let path = "Tests/\(packageName)Tests"
        let exists = directoryExists(path)

        addResult(ValidationResult(category: "Structure",
                                   name: "Tests directory",
                                   passed: exists,
                                   severity: .error,
                                   message: exists ? "Tests/\(packageName)Tests/ found" : "Tests directory not found",
                                   fix: exists ? nil : "Create Tests/\(packageName)Tests/ directory"))
    }

    private func checkDocumentation(applyFixes: Bool) {
        let path = "Documentation.docc"
        var exists = directoryExists(path)

        if !exists, applyFixes {
            if createDirectory(path) {
                let docContent = """
                # ``\(packageName)``

                Brief description of what \(packageName) does.

                ## Overview

                Provide a detailed overview of the package functionality.

                ## Topics

                ### Essentials

                - ``\(packageName)``

                """
                _ = writeFile("\(path)/\(packageName).md", content: docContent)
                fixesApplied.append("Created Documentation.docc/ with template")
                exists = true
            }
        }

        addResult(ValidationResult(category: "Structure",
                                   name: "Documentation.docc",
                                   passed: exists,
                                   severity: .warning,
                                   message: exists ? "DocC catalog found" : "DocC catalog not found",
                                   fix: exists ? nil : "Create Documentation.docc/ with package overview",
                                   canAutoFix: true))
    }

    private func checkGitignore(applyFixes _: Bool) {
        let exists = fileExists(".gitignore")
        addResult(ValidationResult(category: "Structure",
                                   name: ".gitignore exists",
                                   passed: exists,
                                   severity: .info,
                                   message: exists ? ".gitignore found" : ".gitignore not found",
                                   fix: exists ? nil : "Add .gitignore file"))
    }

    // MARK: - Configuration Checks

    private func checkARCDevTools() {
        let gitmodules = fileExists(".gitmodules")
        var hasARCDevTools = false

        if gitmodules, let content = readFile(".gitmodules") {
            hasARCDevTools = content.contains("ARCDevTools")
        }

        // Also check if directory exists
        let dirExists = directoryExists("ARCDevTools")
        let isValid = hasARCDevTools && dirExists

        addResult(ValidationResult(category: "Configuration",
                                   name: "ARCDevTools integration",
                                   passed: isValid,
                                   severity: .error,
                                   message: isValid
                                       ? "ARCDevTools integrated as submodule"
                                       : "ARCDevTools not found or not initialized",
                                   fix: isValid
                                       ? nil
                                       :
                                       "git submodule add https://github.com/arclabs-studio/ARCDevTools && git submodule update --init --recursive",
                                   fixCommand: "git submodule add https://github.com/arclabs-studio/ARCDevTools"))
    }

    private func checkSwiftLint(applyFixes: Bool) {
        var exists = fileExists(".swiftlint.yml")

        if !exists, applyFixes, fileExists("ARCDevTools/configs/swiftlint.yml") {
            let (_, exitCode) = shell("cp ARCDevTools/configs/swiftlint.yml .swiftlint.yml", at: packagePath.path)
            if exitCode == 0 {
                fixesApplied.append("Copied .swiftlint.yml from ARCDevTools")
                exists = true
            }
        }

        addResult(ValidationResult(category: "Configuration",
                                   name: ".swiftlint.yml",
                                   passed: exists,
                                   severity: .error,
                                   message: exists ? "SwiftLint config found" : "SwiftLint config not found",
                                   fix: exists ? nil : "Run ./ARCDevTools/arcdevtools-setup or copy config manually",
                                   fixCommand: "cp ARCDevTools/configs/swiftlint.yml .swiftlint.yml",
                                   canAutoFix: true))
    }

    private func checkSwiftFormat(applyFixes: Bool) {
        var exists = fileExists(".swiftformat")

        if !exists, applyFixes, fileExists("ARCDevTools/configs/swiftformat") {
            let (_, exitCode) = shell("cp ARCDevTools/configs/swiftformat .swiftformat", at: packagePath.path)
            if exitCode == 0 {
                fixesApplied.append("Copied .swiftformat from ARCDevTools")
                exists = true
            }
        }

        addResult(ValidationResult(category: "Configuration",
                                   name: ".swiftformat",
                                   passed: exists,
                                   severity: .error,
                                   message: exists ? "SwiftFormat config found" : "SwiftFormat config not found",
                                   fix: exists ? nil : "Run ./ARCDevTools/arcdevtools-setup or copy config manually",
                                   fixCommand: "cp ARCDevTools/configs/swiftformat .swiftformat",
                                   canAutoFix: true))
    }

    private func checkGitHubWorkflows(applyFixes: Bool) {
        let workflowsDir = ".github/workflows"
        var exists = directoryExists(workflowsDir)

        if !exists, applyFixes {
            if createDirectory(workflowsDir) {
                fixesApplied.append("Created .github/workflows/ directory")
                exists = true
            }
        }

        if exists {
            // Check for CI workflow
            let hasCI = fileExists("\(workflowsDir)/ci.yml") ||
                fileExists("\(workflowsDir)/quality.yml") ||
                fileExists("\(workflowsDir)/tests.yml")

            addResult(ValidationResult(category: "Configuration",
                                       name: "GitHub CI workflow",
                                       passed: hasCI,
                                       severity: .warning,
                                       message: hasCI ? "CI workflow found" : "No CI workflow found",
                                       fix: hasCI ? nil : "Copy workflows from ARCDevTools/workflows/",
                                       fixCommand: "cp ARCDevTools/workflows/*.yml .github/workflows/"))
        } else {
            addResult(ValidationResult(category: "Configuration",
                                       name: "GitHub workflows directory",
                                       passed: false,
                                       severity: .warning,
                                       message: ".github/workflows/ not found",
                                       fix: "Create .github/workflows/ and add CI workflows",
                                       canAutoFix: true))
        }
    }

    private func checkMakefile() {
        let exists = fileExists("Makefile")
        addResult(ValidationResult(category: "Configuration",
                                   name: "Makefile",
                                   passed: exists,
                                   severity: .info,
                                   message: exists ? "Makefile found" : "Makefile not found",
                                   fix: exists ? nil : "Run ./ARCDevTools/arcdevtools-setup to generate Makefile"))
    }

    // MARK: - README Content Checks

    private func checkReadmeContent() {
        guard let content = readFile("README.md") else { return }

        // Check badges
        let hasBadges = content.contains("img.shields.io")
        addResult(ValidationResult(category: "Documentation",
                                   name: "README badges",
                                   passed: hasBadges,
                                   severity: .warning,
                                   message: hasBadges ? "Badges found" : "No badges found in README",
                                   fix: hasBadges ? nil : "Add Swift, Platforms, and License badges at the top"))

        // Check required sections
        let sections: [(String, String, Severity)] = [("Overview", "## 🎯 Overview", .warning),
                                                      ("Requirements", "## 📋 Requirements", .warning),
                                                      ("Installation", "## 🚀 Installation", .warning),
                                                      ("Usage", "## 📖 Usage", .warning),
                                                      ("License section", "## 📄 License", .warning),
                                                      ("Architecture", "## 🏗️", .info),
                                                      ("Testing", "## 🧪", .info),
                                                      ("Contributing", "## 🤝", .info)]

        for (name, marker, severity) in sections {
            let hasSection = content.contains(marker) ||
                content.lowercased().contains("## \(name.lowercased())")
            addResult(ValidationResult(category: "Documentation",
                                       name: "README \(name)",
                                       passed: hasSection,
                                       severity: severity,
                                       message: hasSection ? "\(name) section found" : "\(name) section missing",
                                       fix: hasSection ? nil : "Add \(marker) section to README"))
        }

        // Check for code examples
        let hasCodeExamples = content.contains("```swift")
        addResult(ValidationResult(category: "Documentation",
                                   name: "README code examples",
                                   passed: hasCodeExamples,
                                   severity: .info,
                                   message: hasCodeExamples ? "Swift code examples found" : "No Swift code examples",
                                   fix: hasCodeExamples ? nil : "Add Swift code examples in Usage section"))
    }

    // MARK: - Code Quality Checks

    /// Resolves the pinned binary in `.arc-tools/bin` (installed by `make tools`)
    /// before falling back to PATH, so validation matches what CI runs.
    private func resolveTool(_ name: String) -> String? {
        let pinned = packagePath.appendingPathComponent(".arc-tools/bin/\(name)")
        if FileManager.default.isExecutableFile(atPath: pinned.path) {
            return pinned.path
        }
        let (_, whichExit) = shell("which \(name)")
        return whichExit == 0 ? name : nil
    }

    private func runSwiftLintCheck() {
        // Check if SwiftLint is available
        guard let swiftlint = resolveTool("swiftlint") else {
            addResult(ValidationResult(category: "Code Quality",
                                       name: "SwiftLint available",
                                       passed: false,
                                       severity: .warning,
                                       message: "SwiftLint not installed",
                                       fix: "make tools (installs the pinned version — do not use brew)"))
            return
        }

        // Run SwiftLint
        let (output, exitCode) = shell("\(swiftlint) lint --quiet 2>&1 | head -20", at: packagePath.path)
        let passed = exitCode == 0 && output.isEmpty

        var message = passed ? "No SwiftLint issues" : "SwiftLint found issues"
        if !passed, !output.isEmpty {
            let lineCount = output.components(separatedBy: "\n").count
            message = "SwiftLint found \(lineCount) issue(s)"
        }

        addResult(ValidationResult(category: "Code Quality",
                                   name: "SwiftLint check",
                                   passed: passed,
                                   severity: passed ? .info : .warning,
                                   message: message,
                                   fix: passed
                                       ? nil
                                       : "Run 'swiftlint lint' to see issues, 'swiftlint lint --fix' for auto-fixes",
                                   fixCommand: "swiftlint lint --fix"))
    }

    private func runSwiftFormatCheck() {
        // Check if SwiftFormat is available
        guard let swiftformat = resolveTool("swiftformat") else {
            addResult(ValidationResult(category: "Code Quality",
                                       name: "SwiftFormat available",
                                       passed: false,
                                       severity: .warning,
                                       message: "SwiftFormat not installed",
                                       fix: "make tools (installs the pinned version — do not use brew)"))
            return
        }

        // Run SwiftFormat lint check
        let (output, exitCode) = shell("\(swiftformat) --lint . 2>&1 | head -20", at: packagePath.path)
        let passed = exitCode == 0

        var message = passed ? "Code is properly formatted" : "SwiftFormat found formatting issues"
        if !passed, !output.isEmpty {
            let lineCount = output.components(separatedBy: "\n").filter { !$0.isEmpty }.count
            message = "SwiftFormat found \(lineCount) file(s) with formatting issues"
        }

        addResult(ValidationResult(category: "Code Quality",
                                   name: "SwiftFormat check",
                                   passed: passed,
                                   severity: passed ? .info : .warning,
                                   message: message,
                                   fix: passed ? nil : "Run 'swiftformat .' to auto-format code",
                                   fixCommand: "swiftformat ."))
    }

    private func checkSwiftBuild() {
        if verbose {
            print("  Building package (this may take a moment)...")
        }

        let (output, exitCode) = shell("swift build 2>&1", at: packagePath.path)
        let passed = exitCode == 0

        var message = passed ? "Package builds successfully" : "Build failed"
        if !passed {
            // Extract first error
            let lines = output.components(separatedBy: "\n")
            if let errorLine = lines.first(where: { $0.contains("error:") }) {
                message = "Build failed: \(errorLine.prefix(100))..."
            }
        }

        addResult(ValidationResult(category: "Code Quality",
                                   name: "Swift build",
                                   passed: passed,
                                   severity: .error,
                                   message: message,
                                   fix: passed ? nil : "Fix compilation errors shown by 'swift build'"))
    }

    // MARK: - Test Checks

    private func checkTestsExist() {
        let testsPath = "Tests/\(packageName)Tests"
        guard directoryExists(testsPath) else {
            addResult(ValidationResult(category: "Testing",
                                       name: "Test files exist",
                                       passed: false,
                                       severity: .error,
                                       message: "Tests directory not found",
                                       fix: "Create Tests/\(packageName)Tests/ with test files"))
            return
        }

        // Check for Swift test files
        let (output, _) = shell("find Tests -name '*.swift' -type f | wc -l", at: packagePath.path)
        let testFileCount = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let hasTests = testFileCount > 0

        addResult(ValidationResult(category: "Testing",
                                   name: "Test files exist",
                                   passed: hasTests,
                                   severity: .error,
                                   message: hasTests ? "Found \(testFileCount) test file(s)" : "No test files found",
                                   fix: hasTests ? nil : "Add test files to Tests/\(packageName)Tests/"))
    }
}

// MARK: - Errors

enum ValidatorError: Error, LocalizedError {
    case packageNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .packageNotFound(path):
            "Package not found at: \(path)"
        }
    }
}

// MARK: - Report Generation

extension ValidationReport {
    func generateMarkdown() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var output = """
        # 📊 ARC Package Validation Report

        | Property | Value |
        |----------|-------|
        | **Package** | \(packageName) |
        | **Path** | `\(packagePath)` |
        | **Date** | \(dateFormatter.string(from: timestamp)) |
        | **Status** | \(status) |
        | **Score** | **\(score)%** (\(passedCount)/\(results.count) checks) |

        """

        // Summary by severity
        if failedCount > 0 {
            output += """

            ## 📈 Summary

            | Severity | Count |
            |----------|-------|
            | 🔴 Errors | \(errorCount) |
            | 🟡 Warnings | \(warningCount) |
            | 🔵 Info | \(infoCount) |

            """
        }

        // Fixes applied
        if !fixesApplied.isEmpty {
            output += """

            ## 🔧 Fixes Applied

            """
            for fix in fixesApplied {
                output += "- ✅ \(fix)\n"
            }
            output += "\n"
        }

        // Group results by category
        let categories = ["Structure", "Configuration", "Documentation", "Code Quality", "Testing"]

        for category in categories {
            let categoryResults = results.filter { $0.category == category }
            guard !categoryResults.isEmpty else { continue }

            let passed = categoryResults.filter(\.passed)
            let failed = categoryResults.filter { !$0.passed }

            let categoryIcon = switch category {
            case "Structure": "📁"
            case "Configuration": "⚙️"
            case "Documentation": "📖"
            case "Code Quality": "🧹"
            case "Testing": "🧪"
            default: "📋"
            }

            output += """

            ---

            ## \(categoryIcon) \(category)

            """

            // Passed checks
            if !passed.isEmpty {
                output += "### ✅ Passed (\(passed.count))\n\n"
                for result in passed {
                    output += "- \(result.name)\n"
                }
                output += "\n"
            }

            // Failed checks
            if !failed.isEmpty {
                output += "### ❌ Issues (\(failed.count))\n\n"
                for result in failed.sorted(by: { $0.severity > $1.severity }) {
                    output += """
                    #### \(result.severity.rawValue) \(result.name)

                    **Issue:** \(result.message)

                    """
                    if let fix = result.fix {
                        output += "**Fix:** \(fix)\n\n"
                    }
                    if let command = result.fixCommand {
                        output += "```bash\n\(command)\n```\n\n"
                    }
                }
            }
        }

        // Next steps
        if hasBlockingErrors {
            output += """

            ---

            ## 🚀 Next Steps

            1. Fix all 🔴 **Error** issues before merging to main
            2. Address 🟡 **Warning** issues before next release
            3. Consider 🔵 **Info** suggestions for improvement

            Run with `--fix` flag to auto-apply safe fixes.

            """
        } else if failedCount > 0 {
            output += """

            ---

            ## 🚀 Next Steps

            No blocking errors! Consider addressing the warnings and suggestions above.

            """
        } else {
            output += """

            ---

            ## 🎉 Congratulations!

            This package meets all ARC Labs Studio standards and is ready for release.

            """
        }

        return output
    }
}

// MARK: - Main

func main() {
    let arguments = CommandLine.arguments

    // Parse arguments
    var packagePath = "."
    var shouldFix = false
    var verbose = false

    var i = 1
    while i < arguments.count {
        let arg = arguments[i]
        switch arg {
        case "--fix":
            shouldFix = true
        case "--verbose", "-v":
            verbose = true
        case "--help", "-h":
            printUsage()
            exit(0)
        default:
            if !arg.hasPrefix("-") {
                packagePath = arg
            }
        }
        i += 1
    }

    do {
        let validator = try ARCPackageValidator(path: packagePath, verbose: verbose)
        let report = validator.validate(applyFixes: shouldFix)

        print(report.generateMarkdown())

        // Exit with error code if there are blocking errors
        exit(report.hasBlockingErrors ? 1 : 0)

    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

func printUsage() {
    print("""
    ARC Package Validator
    Validates Swift Packages against ARC Labs Studio standards

    USAGE:
        swift validate.swift [package-path] [options]

    ARGUMENTS:
        package-path    Path to the Swift package (default: current directory)

    OPTIONS:
        --fix          Apply safe automatic fixes
        --verbose, -v  Show detailed progress
        --help, -h     Show this help message

    EXAMPLES:
        swift validate.swift .
        swift validate.swift /path/to/ARCNetworking --fix
        swift validate.swift . --verbose

    EXIT CODES:
        0    All checks passed (or only warnings/info)
        1    Has blocking errors
    """)
}

main()
