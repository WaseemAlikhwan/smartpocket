import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_entity.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final expensesForSelectedMonthProvider =
    FutureProvider.autoDispose<List<ExpenseEntity>>((ref) async {
      final ym = ref.watch(selectedMonthProvider);
      return ref.watch(expenseRepositoryProvider).getForMonth(
        year: ym.year,
        month: ym.month,
      );
    });
