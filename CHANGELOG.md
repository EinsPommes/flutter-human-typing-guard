# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Flutter Human Typing Guard
- Dart package for local typing analysis
- Rust microservice for server-side scoring
- Comprehensive documentation
- CI/CD pipelines with GitHub Actions
- Privacy-first design with GDPR compliance

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- HMAC-SHA256 authentication for server communication
- Rate limiting to prevent abuse
- No personal data collection or storage
- Local-first analysis with optional server communication

## [1.0.0] - 2024-01-01

### Added
- **Dart Package (`human_typing_guard`)**:
  - `TypingEvent` model for capturing typing events
  - `TypingAnalyzer` for local pattern analysis
  - `TypingGuard` main class for coordination
  - `TypingGuardWidget` for Flutter integration
  - `TypingGuardClient` for server communication
  - Feature extraction: IKI, burstiness, entropy, backspace rate, jitter
  - Configurable scoring algorithm with weights
  - Privacy mode for local-only analysis

- **Rust Service (`typing-guard-svc`)**:
  - Axum-based REST API
  - `/healthz` endpoint for health checks
  - `/config` endpoint for configuration
  - `/score` endpoint for typing analysis
  - HMAC-SHA256 request authentication
  - Rate limiting with configurable thresholds
  - CORS support for web applications
  - Structured logging with tracing
  - Prometheus metrics (optional)

- **Documentation**:
  - Comprehensive README with quick start guide
  - Human heuristics explanation with mathematical formulas
  - Privacy and ethics guidelines with GDPR compliance
  - Complete API specification with examples
  - Contributing guidelines for developers
  - Code of conduct for community

- **CI/CD**:
  - GitHub Actions workflows for Dart and Rust
  - Automated testing, linting, and formatting
  - Security auditing with cargo-audit
  - Coverage reporting with Codecov
  - Automated releases to pub.dev and crates.io
  - Pre-built binary releases for multiple platforms

- **Development Tools**:
  - Makefile for common development tasks
  - Docker support for containerized deployment
  - Comprehensive test suites
  - Property-based testing for robustness
  - Integration tests for API endpoints

### Technical Details

#### Typing Analysis Features
- **Inter-Key Intervals (IKI)**: Mean, median, standard deviation, IQR
- **Burstiness**: `B = (σ - μ) / (σ + μ)` based on IKI patterns
- **Entropy**: Local entropy of interval histograms
- **Backspace Rate**: Per 100 keystrokes with human-like thresholds
- **Cadence Jitter**: Mean Absolute Deviation of consecutive IKI differences
- **Outlier Detection**: Ratio of IKI values > 3σ from mean

#### Scoring Algorithm
- Weighted combination of normalized metrics
- Default weights: Speed (30%), Variability (25%), Entropy (20%), Backspace (15%), Jitter (10%)
- Configurable thresholds and weights
- Human-likeness score from 0.0 (bot-like) to 1.0 (human-like)

#### Privacy & Security
- No raw keystroke storage or transmission
- Only aggregated statistical features
- Session-based analysis with UUID4 identifiers
- HMAC-SHA256 request signing
- Rate limiting and CORS protection
- GDPR-compliant design

#### Performance
- Local analysis with < 1ms latency
- Server analysis with < 100ms response time
- Memory-efficient event processing
- Configurable analysis windows
- Minimal resource usage

### Dependencies

#### Dart Package
- `crypto: ^3.0.3` - HMAC signature generation
- `http: ^1.1.0` - HTTP client for server communication
- `uuid: ^4.2.1` - UUID generation for sessions

#### Rust Service
- `axum: ^0.7` - Web framework
- `tokio: ^1.0` - Async runtime
- `serde: ^1.0` - Serialization
- `hmac: ^0.12` - HMAC authentication
- `tracing: ^0.1` - Structured logging
- `governor: ^0.6` - Rate limiting

### Platform Support

#### Dart Package
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

#### Rust Service
- ✅ Linux (x86_64)
- ✅ Windows (x86_64)
- ✅ macOS (x86_64)
- ✅ Docker containers

### Installation

#### Dart Package
```yaml
dependencies:
  human_typing_guard: ^1.0.0
```

#### Rust Service
```bash
cargo install typing-guard-svc
```

#### Pre-built Binaries
Download from GitHub Releases for your platform.

### Quick Start

```dart
import 'package:human_typing_guard/human_typing_guard.dart';

final guard = TypingGuard(
  config: TypingGuardConfig(
    windowMs: 5000,
    minEvents: 20,
    localThreshold: 0.6,
  ),
);

TypingGuardWidget(
  guard: guard,
  child: TextField(controller: _controller),
  onResult: (result) {
    if (result.label == GuardLabel.suspicious) {
      // Handle suspicious behavior
    }
  },
);
```

### Breaking Changes
- None (initial release)

### Migration Guide
- N/A (initial release)

### Known Issues
- None at release time

### Future Roadmap
- [ ] Machine learning models for improved accuracy
- [ ] Federated learning for collaborative improvement
- [ ] Additional platform support (React Native, Vue, Angular)
- [ ] Advanced analytics and reporting
- [ ] Real-time streaming analysis
- [ ] Custom feature extraction plugins

---

For more information, see:
- [README.md](README.md) - Project overview and quick start
- [docs/human-heuristics.md](docs/human-heuristics.md) - Technical details
- [docs/privacy-and-ethics.md](docs/privacy-and-ethics.md) - Privacy guidelines
- [docs/api-spec.md](docs/api-spec.md) - API documentation
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) - Contributing guidelines
