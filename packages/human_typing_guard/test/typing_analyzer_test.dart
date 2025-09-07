import 'package:flutter_test/flutter_test.dart';
import 'package:human_typing_guard/human_typing_guard.dart';

void main() {
  group('TypingAnalyzer', () {
    late TypingAnalyzer analyzer;
    late TypingGuardConfig config;

    setUp(() {
      config = const TypingGuardConfig(
        windowMs: 5000,
        minEvents: 5,
        localThreshold: 0.6,
      );
      analyzer = TypingAnalyzer(config: config);
    });

    tearDown(() {
      analyzer.dispose();
    });

    test('should not emit results with insufficient events', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Add only 3 events (less than minEvents = 5)
      analyzer.addEvent(TypingEvent.character(timestamp: 1000, character: 'a'));
      analyzer.addEvent(TypingEvent.character(timestamp: 1200, character: 'b'));
      analyzer.addEvent(TypingEvent.character(timestamp: 1400, character: 'c'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, isEmpty);
    });

    test('should emit results with sufficient events', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Add 6 events (more than minEvents = 5)
      for (int i = 0; i < 6; i++) {
        analyzer.addEvent(
          TypingEvent.character(
            timestamp: 1000 + (i * 200),
            character: String.fromCharCode(97 + i), // a, b, c, d, e, f
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));
      expect(results.first.score, inInclusiveRange(0.0, 1.0));
    });

    test('should calculate realistic IKI values', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Simulate human-like typing with 150ms average IKI
      final timestamps = [1000, 1150, 1300, 1450, 1600, 1750];
      for (int i = 0; i < timestamps.length; i++) {
        analyzer.addEvent(
          TypingEvent.character(
            timestamp: timestamps[i],
            character: String.fromCharCode(97 + i),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final features = TypingFeatures.fromMap(results.first.details);
      expect(features.ikiMean, closeTo(150.0, 10.0));
      expect(features.ikiStd, greaterThan(0));
    });

    test('should detect backspace events', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Add some typing events
      analyzer.addEvent(TypingEvent.character(timestamp: 1000, character: 'a'));
      analyzer.addEvent(TypingEvent.character(timestamp: 1200, character: 'b'));
      analyzer.addEvent(TypingEvent.character(timestamp: 1400, character: 'c'));

      // Add backspace
      analyzer.addEvent(TypingEvent.backspace(timestamp: 1600));
      analyzer.addEvent(TypingEvent.character(timestamp: 1800, character: 'd'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final features = TypingFeatures.fromMap(results.first.details);
      expect(features.backspacePer100, greaterThan(0));
    });

    test('should detect paste events', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Add some typing events
      analyzer.addEvent(TypingEvent.character(timestamp: 1000, character: 'a'));
      analyzer.addEvent(TypingEvent.character(timestamp: 1200, character: 'b'));

      // Add paste event
      analyzer.addEvent(
        TypingEvent.paste(timestamp: 1400, pastedText: 'hello world'),
      );

      analyzer.addEvent(TypingEvent.character(timestamp: 1600, character: 'c'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final features = TypingFeatures.fromMap(results.first.details);
      expect(features.pasteEvents, equals(1));
    });

    test('should prune old events', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Add events that will be pruned
      analyzer.addEvent(TypingEvent.character(timestamp: 0, character: 'a'));
      analyzer.addEvent(TypingEvent.character(timestamp: 200, character: 'b'));

      // Wait for events to be pruned
      await Future.delayed(const Duration(milliseconds: 100));

      // Add new events
      final now = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 6; i++) {
        analyzer.addEvent(
          TypingEvent.character(
            timestamp: now + (i * 200),
            character: String.fromCharCode(97 + i),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final features = TypingFeatures.fromMap(results.first.details);
      expect(features.eventCount, equals(6));
    });

    test('should handle bot-like typing patterns', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Simulate bot-like typing (very consistent, fast)
      for (int i = 0; i < 10; i++) {
        analyzer.addEvent(
          TypingEvent.character(
            timestamp: 1000 + (i * 50), // Very fast, consistent
            character: String.fromCharCode(97 + i),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final result = results.first;
      expect(result.score, lessThan(0.6)); // Should be suspicious
      expect(result.label, equals(GuardLabel.suspicious));
    });

    test('should handle human-like typing patterns', () async {
      final results = <GuardResult>[];
      analyzer.results.listen(results.add);

      // Simulate human-like typing (variable speed, some mistakes)
      final timestamps = [
        1000,
        1180,
        1350,
        1520,
        1680,
        1850,
        2000,
        2150,
        2300,
        2450,
      ];
      for (int i = 0; i < timestamps.length; i++) {
        analyzer.addEvent(
          TypingEvent.character(
            timestamp: timestamps[i],
            character: String.fromCharCode(97 + i),
          ),
        );
      }

      // Add a backspace (human mistake)
      analyzer.addEvent(TypingEvent.backspace(timestamp: 2500));
      analyzer.addEvent(TypingEvent.character(timestamp: 2650, character: 'k'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, hasLength(1));

      final result = results.first;
      expect(result.score, greaterThan(0.4)); // Should be more human-like
    });
  });
}
