import 'package:flutter/material.dart';

import '../../utils/money_format.dart';

class CashFlowCard extends StatelessWidget {
  const CashFlowCard({
    super.key,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.locale,
    required this.currencyCode,
  });

  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final String locale;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash Flow', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row(context, 'الدخل', incomeMinor),
            const SizedBox(height: 6),
            _row(context, 'المصاريف', expenseMinor),
            const SizedBox(height: 6),
            _row(context, 'الصافي', netMinor),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String title, int minor) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Text(formatMinorUnits(minor, locale, currencyCode: currencyCode)),
      ],
    );
  }
}
