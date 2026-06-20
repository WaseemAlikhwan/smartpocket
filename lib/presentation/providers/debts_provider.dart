import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/debt_entity.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final allDebtsProvider = FutureProvider.autoDispose<List<DebtEntity>>((ref) async {
  return ref.watch(debtRepositoryProvider).getAll();
});

final openDebtsProvider = FutureProvider.autoDispose<List<DebtEntity>>((ref) async {
  return ref.watch(debtRepositoryProvider).getPendingDebts();
});

final debtsOwedByMeProvider = FutureProvider.autoDispose<List<DebtEntity>>((ref) async {
  return ref.watch(debtRepositoryProvider).getByType(DebtType.owedByMe);
});

final debtsOwedToMeProvider = FutureProvider.autoDispose<List<DebtEntity>>((ref) async {
  return ref.watch(debtRepositoryProvider).getByType(DebtType.owedToMe);
});

final settledDebtsForSelectedMonthProvider =
    FutureProvider.autoDispose<List<DebtEntity>>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(debtRepositoryProvider).getSettledForMonth(
    year: ym.year,
    month: ym.month,
  );
});
