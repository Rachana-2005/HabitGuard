import 'package:flutter/material.dart';
import '../core/utils/time_formatter.dart';
import '../models/app_category.dart';

/// Card presenting category screen time with icon, duration, and proportion bar
class CategoryUsageCard extends StatelessWidget {
  final AppCategory category;
  final int minutes;
  final int totalScreenMinutes;
  final VoidCallback? onTap;

  const CategoryUsageCard({
    super.key,
    required this.category,
    required this.minutes,
    required this.totalScreenMinutes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double percentage = totalScreenMinutes > 0
        ? (minutes / totalScreenMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.blueGrey.shade800.withAlpha(80)
              : Colors.blueGrey.shade100.withAlpha(120),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category Icon Container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: category.color.withAlpha(isDark ? 40 : 30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      size: 20,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category Title
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  // Duration & Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        TimeFormatter.formatMinutes(minutes),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Percentage Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: percentage),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, val, _) {
                    return LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.blueGrey.shade800.withAlpha(100)
                          : Colors.blueGrey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
