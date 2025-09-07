import 'dart:async';
import 'dart:math';
import '../models/typing_event.dart';
import '../models/typing_features.dart';
import '../models/guard_result.dart';
import '../models/typing_guard_config.dart';

class TypingAnalyzer {
  final TypingGuardConfig config;
  final List<TypingEvent> _events = [];
  final StreamController<GuardResult> _resultController = StreamController<GuardResult>.broadcast();

  Stream<GuardResult> get results => _resultController.stream;

  TypingAnalyzer({required this.config}) {
    config.validate();
  }

  void addEvent(TypingEvent event) {
    _events.add(event);
    _pruneOldEvents();
    
    if (_events.length >= config.minEvents) {
      final features = _calculateFeatures();
      final score = _calculateScore(features);
      final result = GuardResult.fromScore(
        score: score,
        threshold: config.localThreshold,
        details: features.toMap(),
      );
      
      _resultController.add(result);
    }
  }

  void _pruneOldEvents() {
    if (_events.isEmpty) return;
    
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - config.windowMs;
    _events.removeWhere((event) => event.timestamp < cutoffTime);
  }

  TypingFeatures _calculateFeatures() {
    if (_events.length < 2) {
      return _emptyFeatures();
    }

    final ikis = _calculateInterKeyIntervals();
    if (ikis.isEmpty) {
      return _emptyFeatures();
    }

    final ikiMean = _mean(ikis);
    final ikiStd = _standardDeviation(ikis, ikiMean);
    final ikiIqr = _interquartileRange(ikis);

    // Burstiness: (σ - μ) / (σ + μ)
    final burstiness = ikiStd > 0 ? (ikiStd - ikiMean) / (ikiStd + ikiMean) : 0.0;

    final entropy = _calculateEntropy(ikis);

    final backspaceCount = _events.where((e) => e.isBackspace).length;
    final totalKeystrokes = _events.where((e) => !e.isPaste).length;
    final backspacePer100 = totalKeystrokes > 0 ? (backspaceCount / totalKeystrokes) * 100 : 0.0;

    final pasteEvents = _events.where((e) => e.isPaste).length;
    final jitterMad = _calculateJitterMad(ikis);

    final outlierCount = ikis.where((iki) => (iki - ikiMean).abs() > 3 * ikiStd).length;
    final outlierRatio = ikis.isNotEmpty ? outlierCount / ikis.length : 0.0;

    return TypingFeatures(
      eventCount: _events.length,
      ikiMean: ikiMean,
      ikiStd: ikiStd,
      ikiIqr: ikiIqr,
      burstiness: burstiness,
      entropy: entropy,
      backspacePer100: backspacePer100,
      pasteEvents: pasteEvents,
      jitterMad: jitterMad,
      outlierRatio: outlierRatio,
    );
  }

  List<double> _calculateInterKeyIntervals() {
    final ikis = <double>[];
    final regularEvents = _events.where((e) => !e.isPaste).toList();
    
    for (int i = 1; i < regularEvents.length; i++) {
      final interval = regularEvents[i].timestamp - regularEvents[i - 1].timestamp;
      if (interval > 0 && interval < 10000) { // filter unrealistic intervals
        ikis.add(interval.toDouble());
      }
    }
    
    return ikis;
  }

  double _calculateEntropy(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final min = values.reduce(min);
    final max = values.reduce(max);
    if (min == max) return 0.0;
    
    final binSize = (max - min) / 10;
    final bins = List<int>.filled(10, 0);
    
    for (final value in values) {
      final binIndex = ((value - min) / binSize).floor().clamp(0, 9);
      bins[binIndex]++;
    }
    
    double entropy = 0.0;
    for (final count in bins) {
      if (count > 0) {
        final probability = count / values.length;
        entropy -= probability * log(probability) / ln2;
      }
    }
    
    return entropy;
  }

  double _calculateJitterMad(List<double> ikis) {
    if (ikis.length < 2) return 0.0;
    
    final differences = <double>[];
    for (int i = 1; i < ikis.length; i++) {
      differences.add((ikis[i] - ikis[i - 1]).abs());
    }
    
    if (differences.isEmpty) return 0.0;
    
    final mean = _mean(differences);
    return differences.map((d) => (d - mean).abs()).reduce((a, b) => a + b) / differences.length;
  }

  double _calculateScore(TypingFeatures features) {
    final speedScore = _normalizeSpeed(features.ikiMean);
    final variabilityScore = _normalizeVariability(features.ikiStd, features.burstiness);
    final entropyScore = _normalizeEntropy(features.entropy);
    final backspaceScore = _normalizeBackspace(features.backspacePer100);
    final jitterScore = _normalizeJitter(features.jitterMad);

    final weights = config.featureWeights;
    final score = (speedScore * (weights['speed'] ?? 0.3)) +
                  (variabilityScore * (weights['variability'] ?? 0.25)) +
                  (entropyScore * (weights['entropy'] ?? 0.2)) +
                  (backspaceScore * (weights['backspace'] ?? 0.15)) +
                  (jitterScore * (weights['jitter'] ?? 0.1));

    return score.clamp(0.0, 1.0);
  }

  double _normalizeSpeed(double ikiMean) {
    if (ikiMean < 50) return 0.0; // too fast
    if (ikiMean > 1000) return 0.0; // too slow
    if (ikiMean >= 100 && ikiMean <= 300) return 1.0; // perfect range
    if (ikiMean < 100) return ikiMean / 100;
    return max(0.0, 1.0 - (ikiMean - 300) / 700);
  }

  double _normalizeVariability(double ikiStd, double burstiness) {
    final stdScore = (ikiStd / 100).clamp(0.0, 1.0);
    final burstScore = (burstiness + 1) / 2; // convert [-1,1] to [0,1]
    return (stdScore + burstScore) / 2;
  }

  double _normalizeEntropy(double entropy) {
    if (entropy < 1.0) return 0.0; // too low
    if (entropy > 4.0) return 0.0; // too high
    if (entropy >= 2.0 && entropy <= 3.5) return 1.0; // optimal range
    return entropy / 3.5;
  }

  double _normalizeBackspace(double backspacePer100) {
    if (backspacePer100 < 1.0) return 0.5; // too few mistakes
    if (backspacePer100 > 20.0) return 0.0; // too many mistakes
    if (backspacePer100 >= 2.0 && backspacePer100 <= 10.0) return 1.0; // optimal
    return 1.0 - (backspacePer100 - 10.0) / 10.0;
  }

  double _normalizeJitter(double jitterMad) {
    if (jitterMad < 5.0) return 0.3; // too consistent
    if (jitterMad > 100.0) return 0.0; // too erratic
    if (jitterMad >= 10.0 && jitterMad <= 50.0) return 1.0; // optimal
    return jitterMad / 50.0;
  }

  TypingFeatures _emptyFeatures() {
    return TypingFeatures(
      eventCount: _events.length,
      ikiMean: 0.0,
      ikiStd: 0.0,
      ikiIqr: 0.0,
      burstiness: 0.0,
      entropy: 0.0,
      backspacePer100: 0.0,
      pasteEvents: 0,
      jitterMad: 0.0,
      outlierRatio: 0.0,
    );
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _standardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _interquartileRange(List<double> values) {
    if (values.length < 4) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final q1Index = (sorted.length * 0.25).floor();
    final q3Index = (sorted.length * 0.75).floor();
    return sorted[q3Index] - sorted[q1Index];
  }

  void dispose() {
    _resultController.close();
  }
}
