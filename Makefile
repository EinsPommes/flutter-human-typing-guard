# Development Makefile - because typing commands is boring

.PHONY: help dev test lint format clean build release

# Show this help
help:
	@echo "Flutter Human Typing Guard - Development Commands"
	@echo ""
	@echo "Available commands:"
	@echo "  dev          - Start dev environment (Rust service + Flutter)"
	@echo "  test         - Run all tests (Dart + Rust)"
	@echo "  lint         - Check code quality"
	@echo "  format       - Make code pretty"
	@echo "  clean        - Clean up build artifacts"
	@echo "  build        - Build everything"
	@echo "  release      - Prepare for release"
	@echo "  docker       - Build Docker images"
	@echo "  docs         - Generate docs"
	@echo ""

# Development environment
dev:
	@echo "Starting development environment..."
	@echo "Starting Rust service on port 8080..."
	cd services/typing-guard-svc && cargo run &
	@echo "Rust service started. Visit http://localhost:8080/healthz"
	@echo "Press Ctrl+C to stop"

# Testing
test: test-dart test-rust

test-dart:
	@echo "Running Dart tests..."
	cd packages/human_typing_guard && flutter test

test-rust:
	@echo "Running Rust tests..."
	cd services/typing-guard-svc && cargo test

# Linting
lint: lint-dart lint-rust

lint-dart:
	@echo "Running Dart analysis..."
	cd packages/human_typing_guard && flutter analyze

lint-rust:
	@echo "Running Rust clippy..."
	cd services/typing-guard-svc && cargo clippy -- -D warnings

# Formatting
format: format-dart format-rust

format-dart:
	@echo "Formatting Dart code..."
	cd packages/human_typing_guard && dart format .

format-rust:
	@echo "Formatting Rust code..."
	cd services/typing-guard-svc && cargo fmt

# Cleaning
clean: clean-dart clean-rust

clean-dart:
	@echo "Cleaning Dart build artifacts..."
	cd packages/human_typing_guard && flutter clean

clean-rust:
	@echo "Cleaning Rust build artifacts..."
	cd services/typing-guard-svc && cargo clean

# Building
build: build-dart build-rust

build-dart:
	@echo "Building Dart package..."
	cd packages/human_typing_guard && flutter pub get

build-rust:
	@echo "Building Rust service..."
	cd services/typing-guard-svc && cargo build --release

# Release preparation
release: test lint format
	@echo "Release preparation complete!"
	@echo "Next steps:"
	@echo "1. Update version numbers in pubspec.yaml and Cargo.toml"
	@echo "2. Update CHANGELOG.md"
	@echo "3. Create git tag: git tag v1.0.0"
	@echo "4. Push tag: git push origin v1.0.0"

# Docker
docker: docker-rust

docker-rust:
	@echo "Building Rust service Docker image..."
	cd services/typing-guard-svc && docker build -t typing-guard-svc .

# Documentation
docs: docs-dart docs-rust

docs-dart:
	@echo "Generating Dart documentation..."
	cd packages/human_typing_guard && dart doc

docs-rust:
	@echo "Generating Rust documentation..."
	cd services/typing-guard-svc && cargo doc --no-deps

# Installation
install: install-dart install-rust

install-dart:
	@echo "Installing Dart package..."
	cd packages/human_typing_guard && flutter pub get

install-rust:
	@echo "Installing Rust service..."
	cd services/typing-guard-svc && cargo build

# Security
security: security-dart security-rust

security-dart:
	@echo "Running Dart security checks..."
	cd packages/human_typing_guard && flutter pub audit

security-rust:
	@echo "Running Rust security audit..."
	cd services/typing-guard-svc && cargo audit

# Coverage
coverage: coverage-dart coverage-rust

coverage-dart:
	@echo "Generating Dart test coverage..."
	cd packages/human_typing_guard && flutter test --coverage

coverage-rust:
	@echo "Generating Rust test coverage..."
	cd services/typing-guard-svc && cargo tarpaulin --out Html

# Benchmark
benchmark: benchmark-rust

benchmark-rust:
	@echo "Running Rust benchmarks..."
	cd services/typing-guard-svc && cargo bench

# Check everything
check: test lint format
	@echo "All checks passed!"

# Quick development setup
setup:
	@echo "Setting up development environment..."
	@echo "Installing Flutter dependencies..."
	cd packages/human_typing_guard && flutter pub get
	@echo "Installing Rust dependencies..."
	cd services/typing-guard-svc && cargo build
	@echo "Setup complete!"

# CI simulation
ci: test lint format
	@echo "CI simulation complete!"

# Help for specific targets
help-dart:
	@echo "Dart-specific commands:"
	@echo "  test-dart     - Run Dart tests"
	@echo "  lint-dart     - Run Dart analysis"
	@echo "  format-dart   - Format Dart code"
	@echo "  clean-dart    - Clean Dart build artifacts"
	@echo "  build-dart    - Build Dart package"
	@echo "  docs-dart     - Generate Dart documentation"
	@echo "  coverage-dart - Generate Dart test coverage"

help-rust:
	@echo "Rust-specific commands:"
	@echo "  test-rust     - Run Rust tests"
	@echo "  lint-rust     - Run Rust clippy"
	@echo "  format-rust   - Format Rust code"
	@echo "  clean-rust    - Clean Rust build artifacts"
	@echo "  build-rust    - Build Rust service"
	@echo "  docs-rust     - Generate Rust documentation"
	@echo "  coverage-rust - Generate Rust test coverage"
	@echo "  benchmark-rust- Run Rust benchmarks"
