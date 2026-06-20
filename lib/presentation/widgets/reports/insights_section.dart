import 'package:flutter/material.dart';

import '../../../domain/entities/reports/report_insight.dart';

class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key, required this.insights});

  final List<ReportInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Insights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...insights.map((i) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(i.severity), color: _colorFor(context, i.severity)),
                  title: Text(i.title),
                  subtitle: Text(i.message),
                )),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.info:
        return Icons.info_outline;
      case InsightSeverity.positive:
        return Icons.check_circle_outline;
      case InsightSeverity.warning:
        return Icons.warning_amber_outlined;
    }
  }

  Color _colorFor(BuildContext context, InsightSeverity s) {
    switch (s) {
      case InsightSeverity.info:
        return Theme.of(context).colorScheme.primary;
      case InsightSeverity.positive:
        return Colors.green;
      case InsightSeverity.warning:
        return Theme.of(context).colorScheme.error;
    }
  }
}
