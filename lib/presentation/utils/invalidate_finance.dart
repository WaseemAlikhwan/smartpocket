import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_chart_provider.dart';
import '../providers/budget_overrun_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/budget_month_provider.dart';
import '../providers/categories_list_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/debts_provider.dart';
import '../providers/expense_month_provider.dart';
import '../providers/income_month_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/spent_by_category_provider.dart';
import '../providers/reports/reports_providers.dart';

void invalidateFinanceCaches(WidgetRef ref) {
  ref.invalidate(dashboardSnapshotProvider);
  ref.invalidate(budgetOverrunBannerProvider);
  ref.invalidate(expensesForSelectedMonthProvider);
  ref.invalidate(categorySlicesForChartsProvider);
  ref.invalidate(budgetsForSelectedMonthProvider);
  ref.invalidate(spentByCategoryMapProvider);
  ref.invalidate(incomesForSelectedMonthProvider);
  ref.invalidate(allDebtsProvider);
  ref.invalidate(openDebtsProvider);
  ref.invalidate(settledDebtsForSelectedMonthProvider);
  ref.invalidate(recurringEntriesProvider);
  ref.invalidate(appSettingsProvider);
  ref.invalidate(monthlyBalanceProvider);
  ref.invalidate(monthlyInsightsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(dailyReportProvider);
  ref.invalidate(monthlyReportProvider);
  ref.invalidate(yearlyReportProvider);
  ref.invalidate(monthlyReportInsightsProvider);
}
