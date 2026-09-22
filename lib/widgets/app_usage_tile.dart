import 'package:flutter/material.dart';
import '../models/application_usage.dart';

/// Clean list tile displaying individual application foreground duration and category tag
class AppUsageTile extends StatelessWidget {
  final ApplicationUsage app;
  final int rank;

  const AppUsageTile({
    super.key,
    required this.app,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // App Avatar / Category Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: app.category.color.withAlpha(isDark ? 45 : 30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              app.category.icon,
              size: 22,
              color: app.category.color,
            ),
          ),
          const SizedBox(width: 14),

          // Application Name & Category Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.applicationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: app.category.color.withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        app.category.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: app.category.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(app.percentageOfTotal * 100).toStringAsFixed(0)}% of total',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duration
          Text(
            app.formattedDuration,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
