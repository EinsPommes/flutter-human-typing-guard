import 'dart:async';

class TypingGuardConfig {
  final int windowMs; // analysis window in ms
  final int minEvents; // min events needed for analysis
  final double localThreshold; // 0.0-1.0 threshold for human classification
  final Uri? serverUrl; // optional server URL
  final Future<String> Function()? hmacKeyProvider; // HMAC key for server auth
  final bool sendToServer; // whether to send data to server
  final bool privacyMode; // no server communication
  final Map<String, double> featureWeights; // custom scoring weights
  final bool includeDeviceMotion; // include device motion data

  const TypingGuardConfig({
    this.windowMs = 5000,
    this.minEvents = 20,
    this.localThreshold = 0.6,
    this.serverUrl,
    this.hmacKeyProvider,
    this.sendToServer = false,
    this.privacyMode = true,
    this.featureWeights = const {
      'speed': 0.3,
      'variability': 0.25,
      'entropy': 0.2,
      'backspace': 0.15,
      'jitter': 0.1,
    },
    this.includeDeviceMotion = false,
  });

  factory TypingGuardConfig.privacy() {
    return const TypingGuardConfig(
      privacyMode: true,
      sendToServer: false,
      localThreshold: 0.5,
    );
  }

  factory TypingGuardConfig.withServer({
    required Uri serverUrl,
    required Future<String> Function() hmacKeyProvider,
    double localThreshold = 0.6,
  }) {
    return TypingGuardConfig(
      serverUrl: serverUrl,
      hmacKeyProvider: hmacKeyProvider,
      sendToServer: true,
      privacyMode: false,
      localThreshold: localThreshold,
    );
  }

  void validate() {
    if (windowMs <= 0) {
      throw ArgumentError('windowMs must be positive');
    }
    if (minEvents <= 0) {
      throw ArgumentError('minEvents must be positive');
    }
    if (localThreshold < 0.0 || localThreshold > 1.0) {
      throw ArgumentError('localThreshold must be between 0.0 and 1.0');
    }
    if (sendToServer && serverUrl == null) {
      throw ArgumentError('serverUrl is required when sendToServer is true');
    }
    if (sendToServer && hmacKeyProvider == null) {
      throw ArgumentError(
        'hmacKeyProvider is required when sendToServer is true',
      );
    }

    // Validate feature weights sum to approximately 1.0
    final weightSum = featureWeights.values.fold(
      0.0,
      (sum, weight) => sum + weight,
    );
    if ((weightSum - 1.0).abs() > 0.01) {
      throw ArgumentError(
        'Feature weights must sum to approximately 1.0, got $weightSum',
      );
    }
  }

  @override
  String toString() {
    return 'TypingGuardConfig(windowMs: $windowMs, minEvents: $minEvents, '
        'localThreshold: $localThreshold, sendToServer: $sendToServer, '
        'privacyMode: $privacyMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingGuardConfig &&
        other.windowMs == windowMs &&
        other.minEvents == minEvents &&
        other.localThreshold == localThreshold &&
        other.serverUrl == serverUrl &&
        other.sendToServer == sendToServer &&
        other.privacyMode == privacyMode &&
        other.includeDeviceMotion == includeDeviceMotion;
  }

  @override
  int get hashCode {
    return Object.hash(
      windowMs,
      minEvents,
      localThreshold,
      serverUrl,
      sendToServer,
      privacyMode,
      includeDeviceMotion,
    );
  }
}
