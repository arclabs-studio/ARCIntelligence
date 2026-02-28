# ARCDevTools Makefile (Swift Package)
# Auto-generated - Do not edit manually

.PHONY: help lint format fix build test setup hooks clean

help:
	@echo "ARCDevTools - Available commands:"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Run SwiftFormat (dry-run)"
	@echo "  make fix       - Apply SwiftFormat"
	@echo "  make build     - Build the package"
	@echo "  make test      - Run tests"
	@echo "  make setup     - Re-install hooks and configs"
	@echo "  make hooks     - Re-install git hooks only"
	@echo "  make clean     - Clean build artifacts"

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --config .swiftlint.yml; \
	else \
		echo "⚠️  SwiftLint not installed: brew install swiftlint"; \
	fi

format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat --config .swiftformat --lint .; \
	else \
		echo "⚠️  SwiftFormat not installed: brew install swiftformat"; \
	fi

fix:
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat --config .swiftformat .; \
	else \
		echo "⚠️  SwiftFormat not installed: brew install swiftformat"; \
	fi

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
