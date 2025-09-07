class TypingEvent {
  final int timestamp;
  final String? character;
  final bool isBackspace;
  final bool isPaste;
  final int? keyCode;
  final String source;
  final bool? deviceMotion;

  const TypingEvent({
    required this.timestamp,
    this.character,
    this.isBackspace = false,
    this.isPaste = false,
    this.keyCode,
    this.source = 'keyboard',
    this.deviceMotion,
  });

  factory TypingEvent.character({
    required int timestamp,
    required String character,
    int? keyCode,
    String source = 'keyboard',
    bool? deviceMotion,
  }) {
    return TypingEvent(
      timestamp: timestamp,
      character: character,
      keyCode: keyCode,
      source: source,
      deviceMotion: deviceMotion,
    );
  }

  factory TypingEvent.backspace({
    required int timestamp,
    int? keyCode,
    String source = 'keyboard',
  }) {
    return TypingEvent(
      timestamp: timestamp,
      isBackspace: true,
      keyCode: keyCode,
      source: source,
    );
  }

  factory TypingEvent.paste({
    required int timestamp,
    required String pastedText,
    String source = 'keyboard',
  }) {
    return TypingEvent(
      timestamp: timestamp,
      character: pastedText,
      isPaste: true,
      source: source,
    );
  }

  @override
  String toString() {
    return 'TypingEvent(timestamp: $timestamp, character: $character, '
        'isBackspace: $isBackspace, isPaste: $isPaste, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingEvent &&
        other.timestamp == timestamp &&
        other.character == character &&
        other.isBackspace == isBackspace &&
        other.isPaste == isPaste &&
        other.keyCode == keyCode &&
        other.source == source &&
        other.deviceMotion == deviceMotion;
  }

  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      character,
      isBackspace,
      isPaste,
      keyCode,
      source,
      deviceMotion,
    );
  }
}
