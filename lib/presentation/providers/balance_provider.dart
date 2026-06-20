import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/balance_snapshot.dart';
import '../../domain/entities/smart_insight.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final monthlyBalanceProvider = FutureProvider.autoDispose<BalanceSnapshot>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(balanceRepositoryProvider).snapshotForMonth(
    year: ym.year,
    month: ym.month,
  );
});

final monthlyInsightsProvider = FutureProvider.autoDispose<List<SmartInsight>>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(balanceRepositoryProvider).insightsForMonth(
    year: ym.year,
    month: ym.month,
  );
});
