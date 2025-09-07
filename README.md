# Flutter Human Typing Guard

[![CI](https://github.com/EinsPommes/flutter-human-typing-guard/workflows/CI/badge.svg)](https://github.com/EinsPommes/flutter-human-typing-guard/actions)
[![pub package](https://img.shields.io/pub/v/human_typing_guard.svg)](https://pub.dev/packages/human_typing_guard)
[![crates.io](https://img.shields.io/crates/v/typing-guard-svc.svg)](https://crates.io/crates/typing-guard-svc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

Ever wondered if that user typing in your app is actually human? This package helps you figure that out by analyzing typing patterns - without being creepy about it.

We look at how people type (speed, rhythm, mistakes) and give you a confidence score. No personal data stored, no biometrics, just good old-fashioned heuristics that actually work.

## 🚀 Get Started in 60 Seconds

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  human_typing_guard: ^1.0.0
```

Then wrap your text input:

```dart
TypingGuardWidget(
  child: TextField(controller: _controller),
  onResult: (result) {
    if (result.label == GuardLabel.suspicious) {
      // Maybe show a captcha or slow things down
      showCaptcha();
    }
  },
)
```

That's it! Works offline, respects privacy, and doesn't need a server (though you can use one if you want).

## 🛠️ Real-World Integration

Here's how you'd actually use this in a real app - like a login form:

### 1. Set up the guard

```dart
import 'package:human_typing_guard/human_typing_guard.dart';

final _emailController = TextEditingController();
final _passwordController = TextEditingController();

late final TypingGuard guard;

@override
void initState() {
  super.initState();
  guard = TypingGuard(
    config: TypingGuardConfig(
      windowMs: 5000,           // analyze last 5 seconds
      minEvents: 20,            // need at least 20 keystrokes
      localThreshold: 0.6,      // offline threshold
      sendToServer: true,       // optional server validation
      serverUrl: Uri.parse('https://your-guard-service.com/score'),
      hmacKeyProvider: () async => 'your-secret-key',
    ),
  );

  // Listen to results
  guard.guardResults.listen((result) {
    debugPrint('TypingGuard: ${result.score} → ${result.label}');
  });
}
```

### 2. Wrap your form fields

```dart
TypingGuardWidget(
  guard: guard,
  child: Column(
    children: [
      TextField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
    ],
  ),
)
```

### 3. React to suspicious behavior

```dart
ValueListenableBuilder<GuardResult?>(
  valueListenable: guard.latestResult,
  builder: (_, result, __) {
    final suspicious = (result?.label ?? GuardLabel.unknown) == GuardLabel.suspicious;
    return ElevatedButton(
      onPressed: suspicious ? null : _submitLogin,
      child: Text(suspicious ? 'Verifying...' : 'Login'),
    );
  },
);
```

### 4. Handle the submission

```dart
Future<void> _submitLogin() async {
  final result = guard.latestResult.value;
  if (result == null || result.score < 0.4) {
    // Show captcha or additional verification
    final verified = await showCaptchaDialog(context);
    if (!verified) return;
  }
  
  // Proceed with normal login
  await _performLogin();
}
```

## 🐳 Server Setup (Optional)

If you want server-side validation, here's a quick Docker setup:

```yaml
# docker-compose.yml
services:
  typing-guard:
    image: ghcr.io/your-org/typing-guard-svc:latest
    environment:
      - HMAC_KEY=supersecretkey
      - BIND_ADDR=0.0.0.0:8080
    ports:
      - "8080:8080"
```

Start it:
```bash
docker compose up -d
```

The server provides:
- `POST /score` - analyze typing features
- `GET /healthz` - health check
- `GET /config` - current thresholds

## 💡 Pro Tips

- **Start conservative**: Use higher thresholds initially, then adjust based on your data
- **Don't be creepy**: Never show "You're a bot" messages. Use neutral language like "Please verify"
- **Fallback gracefully**: If the server is down, the client still works offline
- **Monitor everything**: Log anonymized metrics to tune your thresholds
- **Handle edge cases**: IME users, paste events, and accessibility tools need special consideration

## 📊 See It In Action

![Typing Analysis Demo](docs/demo.gif)

*Watch the magic happen - real-time analysis of typing patterns*

## 🏗️ How We Built This

Here's the simple version: your Flutter app analyzes typing locally, and optionally sends some stats to our Rust service for extra validation.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Rust Service    │    │   Analytics     │
│                 │    │                  │    │                 │
│ TypingGuard     │───▶│ /score endpoint  │───▶│ Prometheus      │
│ Widget          │    │ HMAC + RateLimit │    │ (optional)      │
│                 │    │                  │    │                 │
│ Local Analysis  │    │ Server Scoring   │    │ No PII Storage  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔬 The Science Behind It

### What We Measure (Flutter Side)
- **Typing Speed**: How fast between keystrokes (humans vary, bots don't)
- **Rhythm Patterns**: The natural ebb and flow of human typing
- **Mistake Rate**: Real humans make typos, perfect bots don't
- **Timing Jitter**: Small variations that make us human
- **Outlier Detection**: Those weird pauses when you're thinking

### Server Magic (Rust Side)
- **Smart Scoring**: Weights different factors based on what feels human
- **Security First**: Everything signed with HMAC, rate limited
- **No Storage**: We don't keep your data, promise

## 📦 What's Inside

| Component | What It Does | Status |
|-----------|-------------|---------|
| [`human_typing_guard`](packages/human_typing_guard/) | The Flutter package that does the heavy lifting | ✅ Ready to use |
| [`typing-guard-svc`](services/typing-guard-svc/) | Rust service for when you want server-side validation | ✅ Production ready |

## 🛡️ Privacy First (We Mean It)

- **Zero Personal Data**: We only look at typing patterns, not what you type
- **No Tracking**: Each session gets a random ID, no persistent profiles
- **Local by Default**: Everything works offline, server is optional
- **GDPR Friendly**: We're not building a surveillance system here
- **Open Source**: You can see exactly what we're doing

## 📚 Dive Deeper

- [**Developer Guide**](docs/DEVELOPER_GUIDE.md) - Complete integration guide with real examples
- [**How It Works**](docs/human-heuristics.md) - The math behind the magic
- [**Privacy Details**](docs/privacy-and-ethics.md) - Our privacy promises
- [**API Docs**](docs/api-spec.md) - For when you want to get fancy
- [**Contributing**](docs/CONTRIBUTING.md) - Help us make this better

## 🚀 What's Next

We've got big plans:
- [ ] **Smarter AI**: Machine learning models that get better over time
- [ ] **More Platforms**: React Native, Vue, Angular - you name it
- [ ] **Better Analytics**: Insights into typing patterns (anonymized, of course)
- [ ] **Community Tuning**: Let the community help improve detection

## 📄 License

MIT License - use it, modify it, make it better. See [LICENSE](LICENSE) for the legal stuff.

## 🤝 Want to Help?

Found a bug? Have an idea? We'd love your help! Check out our [Contributing Guide](docs/CONTRIBUTING.md) to get started.

**If this project helps you, give it a ⭐ - it makes our day!**

---

*Built with ❤️ for developers who care about user experience and privacy*
