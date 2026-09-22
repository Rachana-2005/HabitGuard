import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/daily_usage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';

/// Interactive Line Chart showing Addiction Risk Score trajectory over time
class RiskTrendChart extends StatelessWidget {
  final List<DailyUsage> dailyList;

  const RiskTrendChart({
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
        child: Center(child: Text('No risk score records available')),
      );
    }

    final reversed = List<DailyUsage>.from(dailyList.reversed);
    final List<FlSpot> spots = [];
    for (int i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].riskScore.toDouble()));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < reversed.length) {
                    final day = reversed[index];
                    return LineTooltipItem(
                      '${day.date}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      children: [
                        TextSpan(
                          text: 'Score: ${day.riskScore}/100 (${day.riskLevel.label})',
                          style: TextStyle(
                            color: day.riskLevel.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              if (value == 60) {
                // High-Risk threshold alert line
                return FlLine(
                  color: RiskColors.critical.withAlpha(120),
                  strokeWidth: 1.2,
                  dashArray: [6, 4],
                );
              }
              return FlLine(
                color: isDark ? Colors.blueGrey.shade800.withAlpha(70) : Colors.blueGrey.shade200.withAlpha(100),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
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
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
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
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primarySeed,
              barWidth: 3.2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final score = spot.y.toInt();
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: RiskColors.getColorForScore(score),
                    strokeWidth: 2,
                    strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primarySeed.withAlpha(isDark ? 80 : 60),
                    AppTheme.primarySeed.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
