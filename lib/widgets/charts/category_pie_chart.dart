import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_category.dart';
import '../../core/utils/time_formatter.dart';

/// Pie/Donut chart displaying category screen-time distribution
class CategoryPieChart extends StatelessWidget {
  final Map<AppCategory, int> categoryTotals;

  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int totalMinutes = categoryTotals.values.fold(0, (sum, val) => sum + val);

    if (totalMinutes <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No category usage data available')),
      );
    }

    final activeEntries = categoryTotals.entries.where((e) => e.value > 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: activeEntries.map((entry) {
                final double pct = (entry.value / totalMinutes) * 100;
                final isSignificant = pct >= 8.0;

                return PieChartSectionData(
                  color: entry.key.color,
                  value: entry.value.toDouble(),
                  title: isSignificant ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: 42,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: activeEntries.map((entry) {
            final double pct = (entry.value / totalMinutes) * 100;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key.displayName}: ${TimeFormatter.formatMinutes(entry.value)} (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
