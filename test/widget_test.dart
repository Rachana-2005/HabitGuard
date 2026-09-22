import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/models/app_category.dart';
import 'package:habitguard/models/application_usage.dart';
import 'package:habitguard/models/risk_assessment.dart';
import 'package:habitguard/widgets/app_usage_tile.dart';
import 'package:habitguard/widgets/category_usage_card.dart';
import 'package:habitguard/widgets/risk_score_gauge.dart';

void main() {
  group('HabitGuard Widget Tests', () {
    testWidgets('RiskScoreGauge renders score and level badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RiskScoreGauge(
                score: 72,
                level: RiskLevel.high,
              ),
            ),
          ),
        ),
      );

      // Verify widget elements
      expect(find.text('RISK SCORE'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(find.text(' / 100'), findsOneWidget);
    });

    testWidgets('CategoryUsageCard renders category, time, and progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryUsageCard(
              category: AppCategory.socialMedia,
              minutes: 130,
              totalScreenMinutes: 300,
            ),
          ),
        ),
      );

      expect(find.text('Social Media'), findsOneWidget);
      expect(find.text('2h 10m'), findsOneWidget);
      expect(find.text('43%'), findsOneWidget);
    });

    testWidgets('AppUsageTile displays application details correctly', (WidgetTester tester) async {
      const app = ApplicationUsage(
        packageName: 'com.google.android.youtube',
        applicationName: 'YouTube',
        category: AppCategory.entertainment,
        usageMilliseconds: 7200000,
        percentageOfTotal: 0.40,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppUsageTile(
              app: app,
              rank: 1,
            ),
          ),
        ),
      );

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('40% of total'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
