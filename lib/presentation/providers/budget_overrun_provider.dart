import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/budget_alert_period.dart';
import 'budget_month_provider.dart';
import '../utils/budget_period_math.dart';
import 'dashboard_provider.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

class BudgetOverrunNotice {
  const BudgetOverrunNotice({
    required this.categoryId,
    required this.period,
  });

  final String categoryId;
  final BudgetAlertPeriod period;
}

final budgetOverrunBannerProvider =
    FutureProvider.autoDispose<BudgetOverrunNotice?>((ref) async {
  final dash = await ref.watch(dashboardSnapshotProvider.future);
  final ym = ref.watch(selectedMonthProvider);
  final budgets = await ref.watch(budgetsForSelectedMonthProvider.future);
  final expenses = ref.watch(expenseRepositoryProvider);
  final spentByCategory = await expenses.sumByCategoryForMonth(
    year: ym.year,
    month: ym.month,
  );

  if (dash.budgetCapSumMinor <= 0 || budgets.isEmpty) return null;

  for (final b in budgets) {
    final monthSpent = spentByCategory[b.categoryId] ?? 0;
    final over = await isCategoryBudgetOverrun(
      period: b.alertPeriod,
      year: ym.year,
      month: ym.month,
      categoryId: b.categoryId,
      categoryLimitMinor: b.limitAmountMinor,
      spentThisMonthMinor: monthSpent,
      sumCategoryBetween: (categoryId, start, end) => expenses.sumForCategoryBetween(
        categoryId: categoryId,
        startInclusive: start,
        endExclusive: end,
      ),
    );
    if (over) {
      return BudgetOverrunNotice(
        categoryId: b.categoryId,
        period: b.alertPeriod,
      );
    }
  }
  return null;
});
