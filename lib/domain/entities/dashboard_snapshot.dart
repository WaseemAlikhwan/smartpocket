/// Aggregates shown on the user home dashboard.
///
/// Remaining budget: sum of monthly budget limits **for categories that have
/// a budget row** this month minus **total expenses this month across all categories**.
/// Categories without an explicit budget row are not included in the cap sum.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.year,
    required this.month,
    required this.currentBalanceMinor,
    required this.totalIncomeMinor,
    required this.totalSpentMinor,
    required this.netSavingMinor,
    required this.budgetCapSumMinor,
    required this.remainingMinor,
    required this.topCategoryId,
    required this.topCategorySpentMinor,
    required this.insights,
    required this.recentExpenses,
  });

  final int year;
  final int month;
  final int currentBalanceMinor;
  final int totalIncomeMinor;
  final int totalSpentMinor;
  final int netSavingMinor;
  final int budgetCapSumMinor;
  final int remainingMinor;
  final String? topCategoryId;
  final int topCategorySpentMinor;
  final List<String> insights;
  final List<RecentExpenseRow> recentExpenses;
}

class RecentExpenseRow {
  const RecentExpenseRow({
    required this.expenseId,
    required this.amountMinor,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.categoryName,
  });

  final String expenseId;
  final int amountMinor;
  final String note;
  final DateTime date;
  final String categoryId;
  final String categoryName;
}
