import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Modular bar chart widget for admin analytics.
class BarChartWidget extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final List<String> xLabels;
  final String? title;
  final double maxY;

  const BarChartWidget({
    Key? key,
    required this.barGroups,
    required this.xLabels,
    this.title,
    required this.maxY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    Text(title!, style: Theme.of(context).textTheme.titleLarge),
              ),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          final idx = value.toInt();
                          return Text(idx < xLabels.length ? xLabels[idx] : '');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modular line chart widget for admin analytics.
class LineChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> xLabels;
  final String? title;
  final double maxY;

  const LineChartWidget({
    Key? key,
    required this.spots,
    required this.xLabels,
    this.title,
    required this.maxY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    Text(title!, style: Theme.of(context).textTheme.titleLarge),
              ),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          final idx = value.toInt();
                          return Text(idx < xLabels.length ? xLabels[idx] : '');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Theme.of(context).primaryColor,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


