import 'trend_point.dart';

/// One month's aggregate inside a yearly report. Used to highlight
/// best/worst months and to drive the 12-bar chart.
class YearlyMonthSummary {
  const YearlyMonthSummary({
    required this.year,
    required this.month,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
  });

  final int year;
  final int month;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}

class YearlyReport {
  const YearlyReport({
    required this.year,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.months,
    required this.bestMonth,
    required this.worstMonth,
    required this.monthlyExpenseSeries,
    required this.monthlyIncomeSeries,
  });

  final int year;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  /// 12 dense entries (Jan..Dec).
  final List<YearlyMonthSummary> months;

  /// Lowest expense among months that had at least one expense; null if
  /// there were no expenses at all in the year.
  final YearlyMonthSummary? bestMonth;

  /// Highest expense; null if no expenses in the year.
  final YearlyMonthSummary? worstMonth;

  final List<TrendPoint> monthlyExpenseSeries;
  final List<TrendPoint> monthlyIncomeSeries;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}
