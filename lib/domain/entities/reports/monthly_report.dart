import 'category_analysis.dart';
import 'comparison_result.dart';
import 'report_insight.dart';
import 'trend_point.dart';

/// Top spending day within a month: a (date, amount) pair, or `null`
/// when there were no expenses in the month.
class TopSpendingDay {
  const TopSpendingDay({
    required this.day,
    required this.amountMinor,
  });

  final DateTime day;
  final int amountMinor;
}

/// Comprehensive monthly aggregate produced by [ReportsRepository].
///
/// All monetary amounts are in minor units of the user's base currency.
/// [dailyExpenseSeries] is dense: contains one entry per day from day 1
/// to the last day of the month (zero-filled).
class MonthlyReport {
  const MonthlyReport({
    required this.year,
    required this.month,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.transactionsCount,
    required this.dailyAverageExpenseMinor,
    required this.topCategory,
    required this.topSpendingDay,
    required this.categories,
    required this.dailyExpenseSeries,
    required this.dailyIncomeSeries,
    required this.expenseComparisonVsPreviousMonth,
    required this.expenseComparisonVsPreviousWeek,
    required this.insights,
  });

  final int year;
  final int month;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int transactionsCount;
  final int dailyAverageExpenseMinor;
  final CategoryAnalysisItem? topCategory;
  final TopSpendingDay? topSpendingDay;
  final List<CategoryAnalysisItem> categories;
  final List<TrendPoint> dailyExpenseSeries;
  final List<TrendPoint> dailyIncomeSeries;
  final ComparisonResult expenseComparisonVsPreviousMonth;
  final ComparisonResult expenseComparisonVsPreviousWeek;
  final List<ReportInsight> insights;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}
