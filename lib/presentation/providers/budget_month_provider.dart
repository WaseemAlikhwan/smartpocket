import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_entity.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final budgetsForSelectedMonthProvider =
    FutureProvider.autoDispose<List<BudgetEntity>>((ref) async {
      final ym = ref.watch(selectedMonthProvider);
      return ref.watch(budgetRepositoryProvider).getForMonth(
        year: ym.year,
        month: ym.month,
      );
    });
