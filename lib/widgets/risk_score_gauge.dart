import 'package:flutter/material.dart';
import '../models/risk_assessment.dart';

/// Circular animated risk gauge displaying digital addiction risk score and level
class RiskScoreGauge extends StatelessWidget {
  final int score;
  final RiskLevel level;
  final VoidCallback? onTap;
  final double size;

  const RiskScoreGauge({
    super.key,
    required this.score,
    required this.level,
    this.onTap,
    this.size = 190.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow / Progress Background
              SizedBox(
                width: size,
                height: size,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: (score / 100.0).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: isDark
                          ? Colors.blueGrey.shade800.withAlpha(120)
                          : Colors.blueGrey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(level.color),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),

              // Inner Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RISK SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: score.toDouble()),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, val, _) {
                          return Text(
                            '${val.round()}',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -1.0,
                            ),
                          );
                        },
                      ),
                      Text(
                        ' / 100',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Risk Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: level.lightColor.withAlpha(isDark ? 50 : 255),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: level.color.withAlpha(140),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      level.fullLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? level.color : level.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
