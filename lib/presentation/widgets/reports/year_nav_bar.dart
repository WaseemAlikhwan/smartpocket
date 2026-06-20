import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reports/selected_year_provider.dart';

class YearNavBar extends ConsumerWidget {
  const YearNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '$year',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
