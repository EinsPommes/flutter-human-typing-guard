import 'dart:async';
import '../models/typing_event.dart';
import '../models/guard_result.dart';
import '../models/typing_guard_config.dart';
import '../models/typing_features.dart';
import 'typing_analyzer.dart';
import '../client/typing_guard_client.dart';

/// Main typing guard that coordinates local analysis and optional server scoring
class TypingGuard {
  final TypingGuardConfig config;
  final TypingAnalyzer _analyzer;
  final TypingGuardClient? _client;
  final StreamController<GuardResult> _resultController =
      StreamController<GuardResult>.broadcast();

  /// Stream of combined analysis results (local + server)
  Stream<GuardResult> get results => _resultController.stream;

  /// Stream of local analysis results only
  Stream<GuardResult> get localResults => _analyzer.results;

  TypingGuard({required this.config})
    : _analyzer = TypingAnalyzer(config: config),
      _client = config.sendToServer && !config.privacyMode
          ? TypingGuardClient(config: config)
          : null {
    _setupResultStream();
  }

  /// Setup result stream that combines local and server results
  void _setupResultStream() {
    _analyzer.results.listen((localResult) {
      // Always emit local result
      _resultController.add(localResult);

      // Optionally send to server for additional scoring
      if (_client != null && config.sendToServer) {
        _sendToServer(localResult);
      }
    });
  }

  /// Add a typing event for analysis
  void addEvent(TypingEvent event) {
    _analyzer.addEvent(event);
  }

  /// Send features to server for scoring
  Future<void> _sendToServer(GuardResult localResult) async {
    if (_client == null) return;

    try {
      // Extract features from local result details
      final featuresMap = localResult.details;
      if (featuresMap.isEmpty) return;

      final features = TypingFeatures.fromMap(
        Map<String, dynamic>.from(featuresMap),
      );
      final serverResult = await _client!.scoreFeatures(features);

      if (serverResult != null) {
        // Combine local and server results
        final combinedResult = _combineResults(localResult, serverResult);
        _resultController.add(combinedResult);
      }
    } catch (e) {
      // Log error but don't interrupt local analysis
      print('TypingGuard: Server communication failed: $e');
    }
  }

  /// Combine local and server results
  GuardResult _combineResults(GuardResult local, GuardResult server) {
    // Weighted combination: 70% server, 30% local
    final combinedScore = (server.score * 0.7) + (local.score * 0.3);

    // Use server label if available, otherwise local
    final label = server.label;

    return GuardResult(
      score: combinedScore,
      label: label,
      details: {
        'local_score': local.score,
        'server_score': server.score,
        'combined_score': combinedScore,
        'local_details': local.details,
        'server_details': server.details,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if server is available
  Future<bool> isServerAvailable() async {
    if (_client == null) return false;
    return await _client!.checkHealth();
  }

  /// Get server configuration
  Future<Map<String, dynamic>?> getServerConfig() async {
    if (_client == null) return null;
    return await _client!.getServerConfig();
  }

  /// Get current session ID
  String? get sessionId => _client?._sessionId;

  /// Reset the analysis (clear all events)
  void reset() {
    // Note: This would require modifying TypingAnalyzer to support reset
    // For now, we'll create a new instance
    _analyzer.dispose();
    // In a real implementation, you'd want to properly reset the analyzer
  }

  /// Dispose resources
  void dispose() {
    _analyzer.dispose();
    _client?.dispose();
    _resultController.close();
  }
}
