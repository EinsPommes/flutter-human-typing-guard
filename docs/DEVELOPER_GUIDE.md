# Developer Guide

Quick guide to integrate human typing detection into your Flutter app.

## 🎯 What It Does

Analyzes typing patterns to detect bots:
- **Typing speed** - humans vary, bots don't
- **Rhythm patterns** - natural human inconsistency  
- **Mistake rate** - humans make typos, perfect bots don't
- **Timing jitter** - small variations that make us human

Result: Score from 0.0 (bot) to 1.0 (human)

## 🚀 Quick Start

### 1. Add dependency

```yaml
dependencies:
  human_typing_guard: ^1.0.0
```

### 2. Wrap your text field

```dart
TypingGuardWidget(
  child: TextField(controller: _controller),
  onResult: (result) {
    print('Score: ${result.score}, Label: ${result.label}');
  },
)
```

Done! Analysis runs automatically.

## 🛠️ Real Example: Login Form

### Setup

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late final TypingGuard _guard;
  GuardResult? _latestResult;

  @override
  void initState() {
    super.initState();
    
    _guard = TypingGuard(
      config: TypingGuardConfig(
        windowMs: 5000,           // analyze last 5 seconds
        minEvents: 20,            // need at least 20 keystrokes
        localThreshold: 0.6,      // offline threshold
      ),
    );

    _guard.guardResults.listen((result) {
      setState(() => _latestResult = result);
    });
  }

  @override
  void dispose() {
    _guard.dispose();
    super.dispose();
  }
```

### UI

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TypingGuardWidget(
              guard: _guard,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ),
            
            SizedBox(height: 16),
            
            TypingGuardWidget(
              guard: _guard,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ),
            
            SizedBox(height: 24),
            
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }
```

### Smart Button

```dart
  Widget _buildLoginButton() {
    final isSuspicious = _latestResult?.label == GuardLabel.suspicious;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSuspicious ? null : _handleLogin,
        child: Text(isSuspicious ? 'Please verify' : 'Login'),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final result = _latestResult;
    
    if (result != null && result.score < 0.3) {
      final verified = await _showVerificationDialog();
      if (!verified) return;
    }
    
    await _performLogin();
  }
```

## 🔧 Configuration

### Custom Settings

```dart
TypingGuard(
  config: TypingGuardConfig(
    windowMs: 10000,        // analyze last 10 seconds
    minEvents: 50,          // need more keystrokes
    localThreshold: 0.7,    // stricter threshold
  ),
)
```

### Server Integration

```dart
TypingGuard(
  config: TypingGuardConfig.withServer(
    serverUrl: Uri.parse('https://your-guard-service.com'),
    hmacKeyProvider: () async => 'your-secret-key',
  ),
)
```

## 🐳 Server Setup

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

Start: `docker compose up -d`

## 🚨 Common Mistakes

- **Too strict thresholds** - catches too many humans
- **No fallbacks** - breaks when server is down  
- **Blocking too early** - before enough data is collected
- **Hardcoded secrets** - use environment variables

## 🎯 Use Cases

- **Login forms** - prevent automated attacks
- **Comment systems** - detect spam
- **Registration** - prevent fake accounts
- **Contact forms** - filter automated submissions

## 💡 Pro Tips

- Start with higher thresholds, then adjust
- Never show "You're a bot" messages
- Always provide fallbacks
- Monitor and log for tuning
