import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/daily_usage.dart';
import '../../core/utils/time_formatter.dart';

/// Interactive Bar Chart displaying daily screen time in hours
class UsageBarChart extends StatelessWidget {
  final List<DailyUsage> dailyList;

  const UsageBarChart({
    super.key,
    required this.dailyList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (dailyList.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No historical screen time available')),
      );
    }

    // Sort ascending for chronological chart view (left to right)
    final reversed = List<DailyUsage>.from(dailyList.reversed);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxHours(reversed),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = reversed[groupIndex];
                return BarTooltipItem(
                  '${day.date}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${TimeFormatter.formatMinutes(day.totalScreenTimeMinutes)} (${day.riskLevel.label})',
                      style: TextStyle(
                        color: day.riskLevel.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < reversed.length) {
                    final date = DateTime.tryParse(reversed[index].date);
                    if (date != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          TimeFormatter.formatWeekday(date),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}h',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                    ),
                  );
                },
                reservedSize: 26,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.blueGrey.shade800.withAlpha(80) : Colors.blueGrey.shade200.withAlpha(120),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(reversed.length, (index) {
            final day = reversed[index];
            final hours = day.totalScreenTimeMinutes / 60.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: hours,
                  color: day.riskLevel.color,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _calculateMaxHours(reversed),
                    color: isDark ? Colors.blueGrey.shade900.withAlpha(90) : Colors.blueGrey.shade50,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _calculateMaxHours(List<DailyUsage> list) {
    double maxH = 6.0;
    for (final d in list) {
      final h = d.totalScreenTimeMinutes / 60.0;
      if (h > maxH) maxH = h;
    }
    return (maxH + 1.0).ceilToDouble();
  }
}
