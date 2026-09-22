import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/providers/history_provider.dart';
import 'package:habitguard/providers/usage_provider.dart';
import 'package:habitguard/services/ai_assistant_engine.dart';

void main() {
  group('AI Assistant Rule-Based Engine Tests', () {
    late UsageProvider usageProvider;
    late HistoryProvider historyProvider;

    setUp(() {
      usageProvider = UsageProvider();
      historyProvider = HistoryProvider();
    });

    test('Answers "What is my screen time today?" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: 'What is my screen time today?',
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains("Today's Screen Time"));
    });

    test('Answers "Which app did I use the most?" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: 'Which app did I use the most?',
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains('Most Used App'));
    });

    test('Answers "What is my risk level?" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: 'What is my risk level?',
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains('Digital Addiction Risk Assessment'));
      expect(response, contains('Risk Level'));
      expect(response, contains('Risk Score'));
    });

    test('Answers "Which category did I use the most?" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: 'Which category did I use the most?',
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains('Category'));
    });

    test('Answers "Compare today\'s usage with yesterday\'s usage" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: "Compare today's usage with yesterday's usage",
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains('Comparison'));
    });

    test('Answers "Give me advice to reduce screen time" dynamically', () {
      final response = AiAssistantEngine.generateResponse(
        query: 'Give me advice to reduce screen time',
        usageProvider: usageProvider,
        historyProvider: historyProvider,
      );

      expect(response, contains('Advice to Reduce Screen Time'));
      expect(response, contains('Digital Sunset'));
    });
  });
}
