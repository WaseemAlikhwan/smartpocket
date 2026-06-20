import 'comparison_result.dart';

/// Aggregated totals for a single calendar day (local time).
class DailyReport {
  const DailyReport({
    required this.day,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.transactionsCount,
    required this.expenseComparisonVsYesterday,
  });

  final DateTime day;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int transactionsCount;
  final ComparisonResult expenseComparisonVsYesterday;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}
