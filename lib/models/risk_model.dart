import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'risk_assessment.dart';

/// Single Explainable AI factor detailing why the ML model predicted a risk
class RiskFactorImpact {
  final String factor;
  final String impact; // "HIGH", "MEDIUM", "LOW"
  final String description;

  const RiskFactorImpact({
    required this.factor,
    required this.impact,
    this.description = '',
  });

  Color get color {
    switch (impact.toUpperCase()) {
      case 'HIGH':
        return RiskColors.high;
      case 'MEDIUM':
        return RiskColors.moderate;
      case 'LOW':
      default:
        return RiskColors.low;
    }
  }

  factory RiskFactorImpact.fromJson(Map<String, dynamic> json) {
    return RiskFactorImpact(
      factor: json['factor'] as String? ?? 'General Activity',
      impact: (json['impact'] as String? ?? 'LOW').toUpperCase(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factor': factor,
      'impact': impact,
      'description': description,
    };
  }
}

/// Output from the Machine Learning Risk Prediction Service
class MlRiskPrediction {
  final int riskScore; // 0 to 100
  final RiskLevel riskLevel;
  final double confidence; // 0.0 to 1.0
  final List<RiskFactorImpact> riskFactors;
  final String trend; // "INCREASING", "DECREASING", "STABLE", "INSUFFICIENT_DATA"
  final bool isMock;
  final String? errorMessage;
  final DateTime timestamp;

  const MlRiskPrediction({
    required this.riskScore,
    required this.riskLevel,
    required this.confidence,
    required this.riskFactors,
    this.trend = 'STABLE',
    this.isMock = false,
    this.errorMessage,
    required this.timestamp,
  });

  /// Factory constructor for successful ML API response
  factory MlRiskPrediction.fromApiResponse(Map<String, dynamic> json, {String trend = 'STABLE', bool isMock = false}) {
    final score = (json['riskScore'] as num?)?.toInt() ?? 0;
    final levelStr = json['riskLevel'] as String? ?? 'LOW';
    final conf = (json['confidence'] ?? json['riskProbability'] as num?)?.toDouble() ?? 0.85;

    final rawFactors = json['riskFactors'] as List<dynamic>? ?? [];
    final factors = rawFactors.map((f) {
      if (f is Map<String, dynamic>) {
        return RiskFactorImpact.fromJson(f);
      } else if (f is String) {
        return RiskFactorImpact(factor: f, impact: 'HIGH', description: f);
      }
      return const RiskFactorImpact(factor: 'General Activity', impact: 'LOW');
    }).toList();

    return MlRiskPrediction(
      riskScore: score.clamp(0, 100),
      riskLevel: RiskLevel.fromString(levelStr),
      confidence: conf,
      riskFactors: factors,
      trend: trend,
      isMock: isMock,
      timestamp: DateTime.now(),
    );
  }

  /// Initial or fallback state when ML service is unavailable
  factory MlRiskPrediction.unavailable({String? message}) {
    return MlRiskPrediction(
      riskScore: 0,
      riskLevel: RiskLevel.low,
      confidence: 0.0,
      riskFactors: const [],
      trend: 'INSUFFICIENT_DATA',
      isMock: false,
      errorMessage: message ?? 'AI Risk Prediction Temporarily Unavailable',
      timestamp: DateTime.now(),
    );
  }

  /// Factory for when insufficient historical data exists
  factory MlRiskPrediction.insufficientData() {
    return MlRiskPrediction(
      riskScore: 0,
      riskLevel: RiskLevel.low,
      confidence: 0.0,
      riskFactors: const [],
      trend: 'INSUFFICIENT_DATA',
      errorMessage: 'Building Your Digital Profile: Not enough historical data for prediction.',
      isMock: false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'riskScore': riskScore,
      'riskLevel': riskLevel.label,
      'confidence': confidence,
      'riskFactors': riskFactors.map((f) => f.toJson()).toList(),
      'trend': trend,
      'isMock': isMock,
      'predictedAt': timestamp.toIso8601String(),
    };
  }
}
