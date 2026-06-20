import 'package:flutter/material.dart';

import '../../../domain/entities/reports/comparison_result.dart';

class ComparisonChip extends StatelessWidget {
  const ComparisonChip({
    super.key,
    required this.label,
    required this.result,
  });

  final String label;
  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String txt;
    switch (result.direction) {
      case ComparisonDirection.up:
        icon = Icons.arrow_upward;
        color = Theme.of(context).colorScheme.error;
        txt = '${result.deltaPct?.toStringAsFixed(1) ?? '--'}%';
        break;
      case ComparisonDirection.down:
        icon = Icons.arrow_downward;
        color = Colors.green;
        txt = '${result.deltaPct?.abs().toStringAsFixed(1) ?? '--'}%';
        break;
      case ComparisonDirection.flat:
        icon = Icons.remove;
        color = Theme.of(context).colorScheme.outline;
        txt = '0%';
        break;
      case ComparisonDirection.undefined:
        icon = Icons.help_outline;
        color = Theme.of(context).colorScheme.outline;
        txt = 'غير متاح';
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(txt, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
