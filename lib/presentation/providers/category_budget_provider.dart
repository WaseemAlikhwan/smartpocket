import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_entity.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final categoryBudgetForSelectedMonthProvider =
    FutureProvider.autoDispose.family<BudgetEntity?, String>((ref, categoryId) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.read(budgetRepositoryProvider).getForCategoryMonth(
        categoryId: categoryId,
        year: ym.year,
        month: ym.month,
      );
});
