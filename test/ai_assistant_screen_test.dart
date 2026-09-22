import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:habitguard/providers/auth_provider.dart';
import 'package:habitguard/providers/history_provider.dart';
import 'package:habitguard/providers/usage_provider.dart';
import 'package:habitguard/screens/ai_assistant/ai_assistant_screen.dart';

void main() {
  group('AI Assistant Screen UI & Response Tests', () {
    Widget buildTestableScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UsageProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: AiAssistantScreen(),
        ),
      );
    }

    testWidgets('Renders AI Assistant screen elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());

      // Verify AppBar and Header Elements
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Live Analytics • Ready'), findsOneWidget);

      // Verify Initial Assistant Welcoming Message
      expect(find.textContaining('HabitGuard AI Assistant'), findsOneWidget);

      // Verify Input Field and Send Button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify Quick Suggestion Chips
      expect(find.text('What is my screen time today?'), findsOneWidget);
    });

    testWidgets('Entering question yields rule-based intelligent response', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());

      // Enter question into the message input field
      await tester.enterText(find.byType(TextField), 'What is my risk level?');
      await tester.pump();

      // Tap Send Button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Verify user message appears in chat
      expect(find.text('What is my risk level?'), findsOneWidget);

      // Advance clock for typing indicator and dynamic response
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Digital Addiction Risk Assessment'), findsOneWidget);
    });

    testWidgets('Tapping suggestion chip automatically queries and answers', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());

      // Tap Quick Suggestion Chip
      await tester.tap(find.text('What is my screen time today?'));
      await tester.pump();

      // Verify user bubble appears
      expect(find.text('What is my screen time today?'), findsAtLeast(1));

      // Advance clock
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining("Today's Screen Time"), findsOneWidget);
    });
  });
}
