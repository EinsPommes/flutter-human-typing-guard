# Contributing

Thanks for wanting to help! We're excited to see new contributors.

## Quick Start

1. Fork the repo
2. Make your changes
3. Run the tests
4. Submit a PR

## What You'll Need

- **Flutter**: 3.10.0+
- **Dart**: 3.0.0+
- **Rust**: 1.70.0+ (for server component)
- **Git**: Obviously
- **Docker**: Optional, but handy

## Setup

1. Fork and clone the repo
2. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/EinsPommes/flutter-human-typing-guard.git
   ```

## Development

### Flutter Package

```bash
cd packages/human_typing_guard
flutter pub get
flutter test
flutter analyze
dart format .
```

### Rust Service

```bash
cd services/typing-guard-svc
cargo build
cargo test
cargo clippy -- -D warnings
cargo fmt
```

### Development Server

```bash
make dev  # Starts Rust service on port 8080
```

## Guidelines

### Types of Contributions

- **Bug Fixes**: Fix existing issues
- **Features**: Add new functionality
- **Documentation**: Improve or add docs
- **Tests**: Add or improve test coverage
- **Performance**: Optimize existing code

### Before Contributing

1. Check existing issues
2. Create issue for significant changes
3. Discuss before implementing
4. Break down large changes into smaller PRs

### Commit Messages

Follow conventional commit format:

```
type(scope): description
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(analyzer): add entropy calculation
fix(client): handle network timeouts
docs(api): update endpoint documentation
```

## Pull Request Process

### Before Submitting

1. Update documentation
2. Add tests for new functionality
3. Update CHANGELOG.md
4. Ensure CI checks pass
5. Self-review your code

### Review Process

1. Automated checks run
2. At least one maintainer reviews
3. Manual testing if needed
4. Maintainer approval required
5. Squash and merge preferred

## Coding Standards

### Dart/Flutter
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for formatting
- Use meaningful variable names
- Add documentation for public APIs

### Rust
- Follow [Rust Style Guide](https://doc.rust-lang.org/1.0.0/style/README.html)
- Use `cargo fmt` and `cargo clippy`
- Use meaningful variable names
- Prefer `Result<T, E>` over panics

## Testing

### Dart Package
```bash
flutter test
flutter test --coverage
```

### Rust Service
```bash
cargo test
cargo tarpaulin --out Html
```

### Requirements
- Unit tests for individual functions
- Integration tests for component interactions
- Maintain >90% test coverage

## Release Process

### Versioning
We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Release Steps
1. Update version in pubspec.yaml and Cargo.toml
2. Update CHANGELOG.md
3. Create git tag (e.g., `v1.0.0`)
4. Publish to pub.dev and crates.io
5. Create GitHub release

## Security

### Reporting Security Issues
- **DO NOT** create public issues
- Email security concerns to: security@example.com
- Include detailed reproduction steps
- Allow time for response before disclosure

### Security Guidelines
- Never commit secrets or API keys
- Use secure coding practices
- Follow OWASP guidelines
- Regular security audits

## Questions?

1. Check this documentation
2. Search existing issues
3. Create a new issue
4. Contact maintainers

Thank you for contributing! 🚀
