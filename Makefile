# ARCDevTools Makefile (Swift Package)
# Auto-generated - Do not edit manually
#
# build/test targets shell out to `swift` for CI and headless use.
# For interactive build, test, and diagnostics, prefer the Xcode MCP
# (see the `arc-mcp-xcode` skill) over running these targets by hand.

.PHONY: help tools lint format fix build test setup hooks clean

help:
	@echo "ARCDevTools - Available commands:"
	@echo "  make tools     - Install pinned SwiftLint/SwiftFormat (.arc-tools/)"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Run SwiftFormat (dry-run)"
	@echo "  make fix       - Apply SwiftFormat"
	@echo "  make build     - Build the package"
	@echo "  make test      - Run tests"
	@echo "  make setup     - Re-install hooks and configs"
	@echo "  make hooks     - Re-install git hooks only"
	@echo "  make clean     - Clean build artifacts"

# Quality targets delegate to ARCDevTools scripts, which resolve the SwiftLint
# and SwiftFormat versions pinned in .arc-tool-versions — the same versions CI
# installs. Run `make tools` once (and after any pin bump) to install them.
tools:
	@./ARCDevTools/scripts/install-tools.sh

lint:
	@./ARCDevTools/scripts/lint.sh

format:
	@./ARCDevTools/scripts/format.sh --dry-run

fix:
	@./ARCDevTools/scripts/format.sh

build:
	@swift build

test:
	@swift test --parallel

setup:
	@./ARCDevTools/arcdevtools-setup

hooks:
	@./ARCDevTools/hooks/install-hooks.sh

clean:
	@rm -rf .build DerivedData
	@echo "✓ Build artifacts removed"
