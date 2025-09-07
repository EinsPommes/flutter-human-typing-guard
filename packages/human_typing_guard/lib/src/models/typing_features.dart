class TypingFeatures {
  final int eventCount;
  final double ikiMean; // ms between keystrokes
  final double ikiStd;
  final double ikiIqr;
  final double burstiness; // (σ - μ) / (σ + μ)
  final double entropy;
  final double backspacePer100;
  final int pasteEvents;
  final double jitterMad;
  final double outlierRatio; // % of IKIs > 3σ

  const TypingFeatures({
    required this.eventCount,
    required this.ikiMean,
    required this.ikiStd,
    required this.ikiIqr,
    required this.burstiness,
    required this.entropy,
    required this.backspacePer100,
    required this.pasteEvents,
    required this.jitterMad,
    required this.outlierRatio,
  });

  Map<String, dynamic> toMap() {
    return {
      'events': eventCount,
      'iki_mean': ikiMean,
      'iki_std': ikiStd,
      'iki_iqr': ikiIqr,
      'burstiness': burstiness,
      'entropy': entropy,
      'backspace_per_100': backspacePer100,
      'paste_events': pasteEvents,
      'jitter_mad': jitterMad,
      'outlier_ratio': outlierRatio,
    };
  }

  factory TypingFeatures.fromMap(Map<String, dynamic> map) {
    return TypingFeatures(
      eventCount: map['events'] as int,
      ikiMean: (map['iki_mean'] as num).toDouble(),
      ikiStd: (map['iki_std'] as num).toDouble(),
      ikiIqr: (map['iki_iqr'] as num).toDouble(),
      burstiness: (map['burstiness'] as num).toDouble(),
      entropy: (map['entropy'] as num).toDouble(),
      backspacePer100: (map['backspace_per_100'] as num).toDouble(),
      pasteEvents: map['paste_events'] as int,
      jitterMad: (map['jitter_mad'] as num).toDouble(),
      outlierRatio: (map['outlier_ratio'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'TypingFeatures(eventCount: $eventCount, ikiMean: ${ikiMean.toStringAsFixed(1)}, '
        'burstiness: ${burstiness.toStringAsFixed(3)}, entropy: ${entropy.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingFeatures &&
        other.eventCount == eventCount &&
        other.ikiMean == ikiMean &&
        other.ikiStd == ikiStd &&
        other.ikiIqr == ikiIqr &&
        other.burstiness == burstiness &&
        other.entropy == entropy &&
        other.backspacePer100 == backspacePer100 &&
        other.pasteEvents == pasteEvents &&
        other.jitterMad == jitterMad &&
        other.outlierRatio == outlierRatio;
  }

  @override
  int get hashCode {
    return Object.hash(
      eventCount,
      ikiMean,
      ikiStd,
      ikiIqr,
      burstiness,
      entropy,
      backspacePer100,
      pasteEvents,
      jitterMad,
      outlierRatio,
    );
  }
}
