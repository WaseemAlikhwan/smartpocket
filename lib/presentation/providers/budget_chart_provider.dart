import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'selected_month_provider.dart';

class CategorySpendSlice {
  const CategorySpendSlice({
    required this.categoryId,
    required this.name,
    required this.amountMinor,
    required this.colorValue,
  });

  final String categoryId;
  final String name;
  final int amountMinor;
  final int colorValue;
}

final categorySlicesForChartsProvider =
    FutureProvider.autoDispose<List<CategorySpendSlice>>((ref) async {
      final ym = ref.watch(selectedMonthProvider);
      final exp = ref.watch(expenseRepositoryProvider);
      final catRepo = ref.watch(categoryRepositoryProvider);
      final sums = await exp.sumByCategoryForMonth(year: ym.year, month: ym.month);
      final cats = await catRepo.getAll();
      final byId = {for (final c in cats) c.id: c};

      final list = <CategorySpendSlice>[];
      for (final e in sums.entries) {
        final c = byId[e.key];
        if (c != null && e.value > 0) {
          list.add(
            CategorySpendSlice(
              categoryId: c.id,
              name: c.name,
              amountMinor: e.value,
              colorValue: c.colorValue,
            ),
          );
        }
      }
      list.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
      return list;
    });
