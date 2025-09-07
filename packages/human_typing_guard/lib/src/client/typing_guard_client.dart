import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/typing_features.dart';
import '../models/guard_result.dart';
import '../models/typing_guard_config.dart';

/// Client for communicating with the typing guard server
class TypingGuardClient {
  final TypingGuardConfig config;
  final http.Client _httpClient;
  final String _sessionId;
  final Map<String, String> _defaultHeaders;

  TypingGuardClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      _sessionId = const Uuid().v4(),
      _defaultHeaders = {
        'Content-Type': 'application/json',
        'User-Agent': 'human_typing_guard/1.0.0',
      };

  /// Send typing features to server for scoring
  Future<GuardResult?> scoreFeatures(TypingFeatures features) async {
    if (config.privacyMode ||
        !config.sendToServer ||
        config.serverUrl == null) {
      return null;
    }

    try {
      final payload = _createPayload(features);
      final signature = await _createSignature(payload);

      final response = await _httpClient
          .post(
            config.serverUrl!,
            headers: {..._defaultHeaders, 'X-Signature': signature},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        throw Exception(
          'Server returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // Log error but don't throw - local analysis should still work
      print('TypingGuard: Server scoring failed: $e');
      return null;
    }
  }

  /// Create payload for server request
  Map<String, dynamic> _createPayload(TypingFeatures features) {
    return {
      'session_id': _sessionId,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'features': features.toMap(),
      'meta': {
        'window_ms': config.windowMs,
        'locale': _getLocale(),
        'platform': _getPlatform(),
        'app_ver': '1.0.0',
      },
    };
  }

  /// Create HMAC signature for request authentication
  Future<String> _createSignature(Map<String, dynamic> payload) async {
    if (config.hmacKeyProvider == null) {
      throw Exception('HMAC key provider not configured');
    }

    final key = await config.hmacKeyProvider!();
    final body = jsonEncode(payload);
    final keyBytes = utf8.encode(key);
    final bodyBytes = utf8.encode(body);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(bodyBytes);

    return 'sha256=${digest.toString()}';
  }

  /// Parse server response
  GuardResult _parseResponse(String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    final score = (data['score'] as num).toDouble();
    final label = data['label'] as String;
    final hints = List<String>.from(data['hints'] ?? []);

    return GuardResult(
      score: score,
      label: label == 'likely_human'
          ? GuardLabel.likelyHuman
          : GuardLabel.suspicious,
      details: {
        'server_score': score,
        'hints': hints,
        'thresholds': data['thresholds'],
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get current locale
  String _getLocale() {
    // In a real implementation, you'd get this from the system
    return 'en_US';
  }

  /// Get current platform
  String _getPlatform() {
    // In a real implementation, you'd detect the actual platform
    return 'flutter';
  }

  /// Check server health
  Future<bool> checkHealth() async {
    if (config.privacyMode || config.serverUrl == null) {
      return false;
    }

    try {
      final healthUrl = config.serverUrl!.resolve('/healthz');
      final response = await _httpClient
          .get(healthUrl, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get server configuration
  Future<Map<String, dynamic>?> getServerConfig() async {
    if (config.privacyMode || config.serverUrl == null) {
      return null;
    }

    try {
      final configUrl = config.serverUrl!.resolve('/config');
      final response = await _httpClient
          .get(configUrl, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore errors
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
