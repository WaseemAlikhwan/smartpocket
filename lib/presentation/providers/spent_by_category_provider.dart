import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'selected_month_provider.dart';

/// Map categoryId → amount spent minor for the globally selected calendar month.
final spentByCategoryMapProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final ym = ref.watch(selectedMonthProvider);
      return ref.watch(expenseRepositoryProvider).sumByCategoryForMonth(
        year: ym.year,
        month: ym.month,
      );
    });
