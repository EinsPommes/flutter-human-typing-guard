enum GuardLabel {
  likelyHuman,
  suspicious,
}

class GuardResult {
  final double score; // 0.0 = bot, 1.0 = human
  final GuardLabel label;
  final Map<String, dynamic> details;
  final int timestamp;

  const GuardResult({
    required this.score,
    required this.label,
    this.details = const {},
    required this.timestamp,
  });

  factory GuardResult.fromScore({
    required double score,
    required double threshold,
    Map<String, dynamic> details = const {},
    int? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return GuardResult(
      score: score,
      label: score >= threshold ? GuardLabel.likelyHuman : GuardLabel.suspicious,
      details: details,
      timestamp: now,
    );
  }

  bool get isHuman => label == GuardLabel.likelyHuman;
  bool get isSuspicious => label == GuardLabel.suspicious;

  @override
  String toString() {
    return 'GuardResult(score: ${score.toStringAsFixed(3)}, '
        'label: $label, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuardResult &&
        other.score == score &&
        other.label == label &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(score, label, timestamp);
  }
}
