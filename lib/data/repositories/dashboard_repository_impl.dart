import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(
    this._expenses,
    this._incomes,
    this._budgets,
    this._categories,
    this._balance,
  );

  final ExpenseRepository _expenses;
  final IncomeRepository _incomes;
  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final BalanceRepository _balance;

  @override
  Future<DashboardSnapshot> snapshotForMonth({
    required int year,
    required int month,
  }) async {
    final balance = await _balance.snapshotForMonth(year: year, month: month);
    final insights = await _balance.insightsForMonth(year: year, month: month);
    final spent = await _expenses.sumForMonth(year: year, month: month);
    final income = await _incomes.sumForMonth(year: year, month: month);
    final cap = await _budgets.sumLimitsForMonth(year: year, month: month);
    final byCat = await _expenses.sumByCategoryForMonth(year: year, month: month);

    String? topId;
    var topAmt = 0;
    for (final e in byCat.entries) {
      if (e.value > topAmt) {
        topAmt = e.value;
        topId = e.key;
      }
    }

    final cats = await _categories.getAll();
    final catNames = {for (final c in cats) c.id: c.name};

    final expenses = await _expenses.getForMonth(year: year, month: month);
    final recent = expenses.take(8).map((e) {
      return RecentExpenseRow(
        expenseId: e.id,
        amountMinor: e.amountMinor,
        note: e.note,
        date: e.date,
        categoryId: e.categoryId,
        categoryName: catNames[e.categoryId] ?? '…',
      );
    }).toList();

    /// Cap sum includes only categories with an explicit monthly budget row.
    /// Total spend is across **all** categories for the month.
    final remaining = cap - spent;

    return DashboardSnapshot(
      year: year,
      month: month,
      currentBalanceMinor: balance.currentBalanceMinor,
      totalIncomeMinor: income,
      totalSpentMinor: spent,
      netSavingMinor: balance.netSavingMinor,
      budgetCapSumMinor: cap,
      remainingMinor: remaining,
      topCategoryId: topId,
      topCategorySpentMinor: topAmt,
      insights: insights.map((e) => e.message).toList(growable: false),
      recentExpenses: recent,
    );
  }
}
