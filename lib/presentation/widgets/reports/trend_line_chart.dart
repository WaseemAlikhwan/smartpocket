import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/reports/trend_point.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.title,
    required this.expenseSeries,
    required this.incomeSeries,
  });

  final String title;
  final List<TrendPoint> expenseSeries;
  final List<TrendPoint> incomeSeries;

  @override
  Widget build(BuildContext context) {
    if (expenseSeries.isEmpty && incomeSeries.isEmpty) return const SizedBox.shrink();
    final maxExpense = expenseSeries.map((e) => e.valueMinor.toDouble()).fold<double>(0, (a, b) => a > b ? a : b);
    final maxIncome = incomeSeries.map((e) => e.valueMinor.toDouble()).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxExpense > maxIncome ? maxExpense : maxIncome;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 1 : maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < expenseSeries.length; i++)
                          FlSpot(i.toDouble(), expenseSeries[i].valueMinor.toDouble()),
                      ],
                      isCurved: true,
                      color: Colors.redAccent,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < incomeSeries.length; i++)
                          FlSpot(i.toDouble(), incomeSeries[i].valueMinor.toDouble()),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      dotData: const FlDotData(show: false),
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
