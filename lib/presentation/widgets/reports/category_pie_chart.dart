import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/reports/category_analysis.dart';
import '../../utils/money_format.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.locale,
    required this.currencyCode,
  });

  final List<CategoryAnalysisItem> categories;
  final String locale;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تحليل حسب الفئات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    for (final c in categories)
                      PieChartSectionData(
                        color: Color(c.colorValue),
                        value: c.amountMinor.toDouble(),
                        title: '${c.percent.toStringAsFixed(1)}%',
                      ),
                  ],
                ),
              ),
            ),
            for (final c in categories)
              ListTile(
                dense: true,
                leading: Icon(Icons.circle, color: Color(c.colorValue), size: 12),
                title: Text(c.name),
                trailing: Text(
                  formatMinorUnits(c.amountMinor, locale, currencyCode: currencyCode),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
