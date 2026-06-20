import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/income_entity.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final incomesForSelectedMonthProvider =
    FutureProvider.autoDispose<List<IncomeEntity>>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(incomeRepositoryProvider).getForMonth(
    year: ym.year,
    month: ym.month,
  );
});
