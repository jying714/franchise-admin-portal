import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ErrorLogTrendChart extends StatelessWidget {
  final List<DateTime> timestamps;
  final int days; // e.g., last 7 or 30 days
  final Color color;
  final String? label;

  /// [timestamps] - list of error log DateTimes to plot
  /// [days] - number of days in the past to show (e.g., 7 or 30)
  /// [color] - color for the line/bar
  /// [label] - optional label for accessibility

  const ErrorLogTrendChart({
    Key? key,
    required this.timestamps,
    this.days = 7,
    this.color = Colors.red,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Count errors per day for [days] days
    final now = DateTime.now();
    final dayCounts = List.generate(days, (i) => 0);
    for (final t in timestamps) {
      final diff = now.difference(DateTime(t.year, t.month, t.day)).inDays;
      if (diff >= 0 && diff < days) {
        dayCounts[days - 1 - diff] += 1; // reverse order for left-to-right
      }
    }
    final maxCount = (dayCounts.isNotEmpty)
        ? (dayCounts.reduce((a, b) => a > b ? a : b))
        : 1;

    return SizedBox(
      height: 80,
      width: days * 16.0 + 40,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount + 1).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, m) {
                  int idx = v.toInt();
                  if (idx < 0 || idx >= days) return const SizedBox.shrink();
                  final date = now.subtract(Duration(days: days - 1 - idx));
                  return Text(
                    days <= 7
                        ? DateFormat('E').format(date)
                        : DateFormat('M/d').format(date),
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dayCounts[i].toDouble(),
                  color: color,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
