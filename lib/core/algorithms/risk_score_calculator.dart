import 'dart:math';
import '../constants/app_constants.dart';
import '../../models/app_category.dart';
import '../../models/risk_assessment.dart';
import '../utils/time_formatter.dart';

/// Transparent, mathematically robust digital addiction risk score algorithm.
/// Computes a normalized score (0 - 100) and provides personalized recommendations.
class RiskScoreCalculator {
  /// Calculates comprehensive risk assessment based on category screen time in minutes.
  static RiskAssessment calculate({
    required int totalScreenTimeMinutes,
    required int socialMediaMinutes,
    required int gamingMinutes,
    required int entertainmentMinutes,
    int educationMinutes = 0,
    int productivityMinutes = 0,
    int communicationMinutes = 0,
    int otherMinutes = 0,
    DateTime? date,
  }) {
    if (totalScreenTimeMinutes <= 0) {
      return RiskAssessment.zero(date: date);
    }

    // ----------------------------------------------------
    // 1. Total Screen Time Factor (0.0 to 100.0)
    // ----------------------------------------------------
    // 0 - 2h (0-120m):   0 - 25 pts  (Healthy)
    // 2 - 4h (120-240m): 25 - 55 pts (Moderate)
    // 4 - 6h (240-360m): 55 - 75 pts (High)
    // 6 - 8h+ (360-480m+): 75 - 100 pts (Critical)
    double screenTimeScore;
    if (totalScreenTimeMinutes <= 120) {
      screenTimeScore = (totalScreenTimeMinutes / 120.0) * 25.0;
    } else if (totalScreenTimeMinutes <= 240) {
      screenTimeScore = 25.0 + ((totalScreenTimeMinutes - 120) / 120.0) * 30.0;
    } else if (totalScreenTimeMinutes <= 360) {
      screenTimeScore = 55.0 + ((totalScreenTimeMinutes - 240) / 120.0) * 20.0;
    } else {
      // 6+ hours
      final overage = min(120, totalScreenTimeMinutes - 360);
      screenTimeScore = 75.0 + (overage / 120.0) * 25.0;
    }

    // ----------------------------------------------------
    // 2. High-Dopamine Category Scores (0.0 to 100.0)
    // ----------------------------------------------------
    // Social Media: Heavy risk multiplier
    // 0-30m: low, 30-90m: moderate, 90-180m+: high
    final double socialScore = min(100.0, (socialMediaMinutes / 150.0) * 100.0);

    // Gaming: High engagement loop
    // 0-30m: low, 30-90m: moderate, 90-150m+: high
    final double gamingScore = min(100.0, (gamingMinutes / 120.0) * 100.0);

    // Entertainment: Passive media consumption
    // 0-60m: low, 60-180m: moderate/high
    final double entertainmentScore = min(100.0, (entertainmentMinutes / 180.0) * 100.0);

    // Other & Communication
    final int nonDopamineMins = communicationMinutes + otherMinutes;
    final double otherScore = min(100.0, (nonDopamineMins / 120.0) * 100.0);

    // ----------------------------------------------------
    // 3. Weighted Base Score Calculation
    // ----------------------------------------------------
    double compositeScore = (screenTimeScore * AppConstants.weightTotalScreenTime) +
        (socialScore * AppConstants.weightSocialMedia) +
        (gamingScore * AppConstants.weightGaming) +
        (entertainmentScore * AppConstants.weightEntertainment) +
        (otherScore * AppConstants.weightOther);

    // ----------------------------------------------------
    // 4. Productive / Educational Usage Mitigation
    // ----------------------------------------------------
    // If a significant portion is educational/productive, mitigate addiction score
    final int productiveMins = educationMinutes + productivityMinutes;
    if (productiveMins > 0 && totalScreenTimeMinutes > 0) {
      final double productiveRatio = productiveMins / totalScreenTimeMinutes;
      // Mitigate up to 18 points if 60%+ is productive
      final double discount = min(18.0, productiveRatio * 25.0);
      compositeScore = max(5.0, compositeScore - discount);
    }

    // Strict clamp between 0 and 100
    final int finalScore = compositeScore.round().clamp(0, 100);
    final RiskLevel riskLevel = RiskLevel.fromScore(finalScore);

    // Category breakdown map
    final Map<AppCategory, int> categoryMap = {
      AppCategory.socialMedia: socialMediaMinutes,
      AppCategory.gaming: gamingMinutes,
      AppCategory.entertainment: entertainmentMinutes,
      AppCategory.education: educationMinutes,
      AppCategory.productivity: productivityMinutes,
      AppCategory.communication: communicationMinutes,
      AppCategory.other: otherMinutes,
    };

    // Determine highest usage category
    AppCategory topCat = AppCategory.other;
    int maxMins = -1;
    categoryMap.forEach((category, minutes) {
      if (minutes > maxMins) {
        maxMins = minutes;
        topCat = category;
      }
    });

    // Generate personalized AI / algorithmic recommendations
    final List<String> recommendations = _generateRecommendations(
      score: finalScore,
      level: riskLevel,
      topCategory: topCat,
      totalMinutes: totalScreenTimeMinutes,
      categoryMap: categoryMap,
    );

    return RiskAssessment(
      score: finalScore,
      level: riskLevel,
      topCategory: topCat,
      categoryMinutes: categoryMap,
      recommendations: recommendations,
      assessmentDate: date ?? DateTime.now(),
    );
  }

  /// Generates dynamic actionable recommendations based on primary addiction drivers
  static List<String> _generateRecommendations({
    required int score,
    required RiskLevel level,
    required AppCategory topCategory,
    required int totalMinutes,
    required Map<AppCategory, int> categoryMap,
  }) {
    final List<String> tips = [];
    final totalFormatted = TimeFormatter.formatMinutes(totalMinutes);

    // 1. Category-specific primary advice
    final topMinutes = categoryMap[topCategory] ?? 0;
    final topFormatted = TimeFormatter.formatMinutes(topMinutes);

    switch (topCategory) {
      case AppCategory.socialMedia:
        if (topMinutes > 60) {
          tips.add('You spent $topFormatted on social media today. Try enabling app limits or greyscale mode on Instagram/TikTok to curb mindless scrolling.');
        } else {
          tips.add('Social media was your most active category today ($topFormatted). Keep your session intervals brief.');
        }
        break;
      case AppCategory.gaming:
        if (topMinutes > 60) {
          tips.add('Gaming accounted for $topFormatted today. Set a mandatory 10-minute movement break between gaming sessions.');
        } else {
          tips.add('Gaming was your top activity ($topFormatted). Good job maintaining moderate play duration.');
        }
        break;
      case AppCategory.entertainment:
        if (topMinutes > 90) {
          tips.add('You watched $topFormatted of entertainment streaming. Try swapping the last 30 minutes before sleep for a book or podcast.');
        } else {
          tips.add('Entertainment streaming was your primary activity ($topFormatted).');
        }
        break;
      case AppCategory.education:
      case AppCategory.productivity:
        tips.add('Great focus! $topFormatted was dedicated to ${topCategory.displayName.toLowerCase()}, demonstrating healthy and purposeful smartphone use.');
        break;
      case AppCategory.communication:
        tips.add('Communication apps accounted for $topFormatted. Ensure messaging does not interrupt your focused work blocks.');
        break;
      case AppCategory.shopping:
        tips.add('Shopping apps were active today ($topFormatted). Consider adding items to a 24-hour wishlist before purchasing.');
        break;
      case AppCategory.other:
        tips.add('Your usage is spread across various utility applications today.');
        break;
    }

    // 2. Risk Level-based safety advice
    if (level == RiskLevel.critical) {
      tips.add('CRITICAL SCREEN TIME: Total phone usage reached $totalFormatted today. Put your device in "Do Not Disturb" mode and keep it out of reach during rest hours.');
      tips.add('High-Risk notification active: Your configured guardian may receive an automated wellbeing alert.');
    } else if (level == RiskLevel.high) {
      tips.add('HIGH RISK: You accumulated $totalFormatted of screen time. Aim to reduce total phone time by at least 45 minutes tomorrow.');
      tips.add('Avoid using your phone during meals and 1 hour before bedtime.');
    } else if (level == RiskLevel.moderate) {
      tips.add('MODERATE: Your screen time is $totalFormatted. Monitor app notifications to prevent impulsive unlocks throughout the day.');
    } else {
      tips.add('EXCELLENT: Your digital habits are within the healthy daily baseline (under 2 hours). Keep maintaining this healthy balance!');
    }

    return tips;
  }
}
