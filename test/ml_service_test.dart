import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/models/behavioral_features.dart';
import 'package:habitguard/models/risk_assessment.dart';
import 'package:habitguard/models/risk_model.dart';
import 'package:habitguard/services/ml_service.dart';

void main() {
  group('ML Prediction Parsing & Service Tests', () {
    test('Correctly parses valid ML prediction API response with XAI factors', () {
      final jsonResponse = {
        'riskLevel': 'HIGH',
        'riskProbability': 0.82,
        'riskScore': 78,
        'confidence': 0.82,
        'topRiskFactors': ['Late Night Usage', 'Social Media Usage'],
        'riskFactors': [
          {
            'factor': 'Late Night Usage',
            'impact': 'HIGH',
            'description': '84 minutes of smartphone activity detected past 11 PM.',
          },
          {
            'factor': 'Social Media Usage',
            'impact': 'HIGH',
            'description': 'Social media accounts for 45.2% of daily screen time.',
          },
          {
            'factor': 'Productive Usage',
            'impact': 'LOW',
            'description': '35 minutes spent on educational apps.',
          },
        ],
      };

      final prediction = MlRiskPrediction.fromApiResponse(
        jsonResponse,
        trend: 'INCREASING',
        isMock: false,
      );

      expect(prediction.riskScore, equals(78));
      expect(prediction.riskLevel, equals(RiskLevel.high));
      expect(prediction.confidence, equals(0.82));
      expect(prediction.trend, equals('INCREASING'));
      expect(prediction.isMock, isFalse);
      expect(prediction.riskFactors.length, equals(3));

      final firstFactor = prediction.riskFactors.first;
      expect(firstFactor.factor, equals('Late Night Usage'));
      expect(firstFactor.impact, equals('HIGH'));
    });

    test('Generates structured mock prediction when mock mode is enabled', () async {
      final mlService = MlService();

      final features = const BehavioralFeatures(
        totalScreenTime: 360,
        socialMediaTime: 180,
        gamingTime: 60,
        entertainmentTime: 40,
        educationTime: 20,
        productivityTime: 20,
        communicationTime: 20,
        otherTime: 20,
        numberOfAppSessions: 55,
        averageSessionDuration: 6.5,
        lateNightUsage: 75,
        earlyMorningUsage: 15,
        mostUsedCategory: 'SOCIALMEDIA',
        mostUsedApplication: 'Instagram',
        numberOfFrequentlyOpenedApps: 3,
        dailyUsageChangePercentage: 25.0,
        previousDayScreenTime: 280,
        sevenDayAverageScreenTime: 290.0,
        sevenDayRiskTrend: 'INCREASING',
        socialMediaPercentage: 50.0,
        gamingPercentage: 16.7,
        productiveUsagePercentage: 11.1,
        entertainmentPercentage: 11.1,
        usageAfter11PM: 75,
        usageBefore7AM: 15,
        isWeekend: false,
      );

      final mockPrediction = await mlService.predictRisk(features, forceMock: true);

      expect(mockPrediction.isMock, isTrue);
      expect(mockPrediction.riskScore, greaterThanOrEqualTo(50));
      expect(mockPrediction.riskFactors.isNotEmpty, isTrue);
      expect(mockPrediction.riskFactors.any((f) => f.factor == 'Late Night Usage'), isTrue);
    });

    test('Gracefully handles service unavailable state without crashing', () {
      final unavailable = MlRiskPrediction.unavailable(message: 'Connection timed out');
      expect(unavailable.riskScore, equals(0));
      expect(unavailable.riskLevel, equals(RiskLevel.low));
      expect(unavailable.errorMessage, equals('Connection timed out'));
      expect(unavailable.riskFactors, isEmpty);
    });
  });
}
