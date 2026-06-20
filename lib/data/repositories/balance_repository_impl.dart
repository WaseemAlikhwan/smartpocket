import '../../domain/entities/balance_snapshot.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/smart_insight.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/settings_repository.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl(
    this._settings,
    this._expenses,
    this._incomes,
    this._debts,
    this._categories,
  );

  final SettingsRepository _settings;
  final ExpenseRepository _expenses;
  final IncomeRepository _incomes;
  final DebtRepository _debts;
  final CategoryRepository _categories;

  @override
  Future<BalanceSnapshot> snapshotForMonth({required int year, required int month}) async {
    final settings = await _settings.get();
    final opening = settings?.openingBalanceMinor ?? 0;
    final income = await _incomes.sumForMonth(year: year, month: month);
    final expense = await _expenses.sumForMonth(year: year, month: month);
    final settledDebts = await _debts.getSettledForMonth(year: year, month: month);

    var debtCashflow = 0;
    for (final d in settledDebts) {
      final paid = d.paidAmountMinor > 0 ? d.paidAmountMinor : d.amountMinor;
      if (d.type == DebtType.owedToMe) {
        debtCashflow += paid;
      } else {
        debtCashflow -= paid;
      }
    }

    final currentBalance = opening + income - expense + debtCashflow;
    final netSaving = income - expense;

    return BalanceSnapshot(
      year: year,
      month: month,
      openingBalanceMinor: opening,
      totalIncomeMinor: income,
      totalExpenseMinor: expense,
      debtCashflowMinor: debtCashflow,
      currentBalanceMinor: currentBalance,
      netSavingMinor: netSaving,
    );
  }

  @override
  Future<List<SmartInsight>> insightsForMonth({required int year, required int month}) async {
    final out = <SmartInsight>[];
    final thisMonthByCategory =
        await _expenses.sumByCategoryForMonth(year: year, month: month);
    if (thisMonthByCategory.isNotEmpty) {
      String? topId;
      var topValue = 0;
      for (final e in thisMonthByCategory.entries) {
        if (e.value > topValue) {
          topValue = e.value;
          topId = e.key;
        }
      }
      if (topId != null) {
        final cats = await _categories.getAll();
        var name = 'فئة غير معروفة';
        for (final c in cats) {
          if (c.id == topId) {
            name = c.name;
            break;
          }
        }
        out.add(SmartInsight(title: 'أعلى فئة صرف', message: 'أكثر فئة تصرف عليها هي: $name'));
      }
    }

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final currentSpent = await _expenses.sumForMonth(year: year, month: month);
    final prevSpent = await _expenses.sumForMonth(year: prevYear, month: prevMonth);
    if (prevSpent > 0) {
      final deltaPct = ((currentSpent - prevSpent) / prevSpent) * 100;
      final trend = deltaPct >= 0 ? 'زاد' : 'انخفض';
      out.add(
        SmartInsight(
          title: 'مقارنة بالشهر الماضي',
          message: 'مصروفك $trend بنسبة ${deltaPct.abs().toStringAsFixed(1)}%',
        ),
      );
    }

    return out;
  }
}
