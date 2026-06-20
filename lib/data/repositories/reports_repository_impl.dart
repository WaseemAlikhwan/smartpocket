import 'package:intl/intl.dart';

import '../../domain/entities/reports/category_analysis.dart';
import '../../domain/entities/reports/comparison_result.dart';
import '../../domain/entities/reports/daily_report.dart';
import '../../domain/entities/reports/monthly_report.dart';
import '../../domain/entities/reports/report_insight.dart';
import '../../domain/entities/reports/trend_point.dart';
import '../../domain/entities/reports/yearly_report.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._expenses, this._incomes, this._categories);

  final ExpenseRepository _expenses;
  final IncomeRepository _incomes;
  final CategoryRepository _categories;

  static final DateFormat _dayKeyFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayLabelFmt = DateFormat('d');
  static const List<String> _monthLabels = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  DateTime _startOfDayLocal(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _startOfMonthLocal(int year, int month) => DateTime(year, month, 1);
  DateTime _endOfMonthLocal(int year, int month) => DateTime(year, month + 1, 1);

  @override
  Future<DailyReport> dailyReport(DateTime day) async {
    final start = _startOfDayLocal(day);
    final end = start.add(const Duration(days: 1));
    final prevStart = start.subtract(const Duration(days: 1));

    final totalIncomeMinor = await _incomes.sumBetween(
      startInclusive: start,
      endExclusive: end,
    );
    final totalExpenseMinor = await _expenses.sumBetween(
      startInclusive: start,
      endExclusive: end,
    );
    final transactionsCount = await _expenses.countBetween(
      startInclusive: start,
      endExclusive: end,
    );
    final prevExpense = await _expenses.sumBetween(
      startInclusive: prevStart,
      endExclusive: start,
    );

    return DailyReport(
      day: start,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
      transactionsCount: transactionsCount,
      expenseComparisonVsYesterday: ComparisonResult.from(
        currentMinor: totalExpenseMinor,
        previousMinor: prevExpense,
      ),
    );
  }

  @override
  Future<MonthlyReport> monthlyReport({required int year, required int month}) async {
    final monthStart = _startOfMonthLocal(year, month);
    final monthEnd = _endOfMonthLocal(year, month);
    final isCurrentMonth = _isSameMonth(monthStart, DateTime.now());
    final daysInMonth = monthEnd.subtract(const Duration(days: 1)).day;
    final daysElapsed = isCurrentMonth ? DateTime.now().day : daysInMonth;

    final totalIncomeMinor = await _incomes.sumBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );
    final totalExpenseMinor = await _expenses.sumBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );
    final transactionsCount = await _expenses.countBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );

    final byDayExpense = await _expenses.sumByDayBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );
    final byDayIncome = await _incomes.sumByDayBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );
    final byCategory = await _expenses.sumByCategoryBetween(
      startInclusive: monthStart,
      endExclusive: monthEnd,
    );
    final categories = await _buildCategoryAnalysis(
      byCategory: byCategory,
      totalExpenseMinor: totalExpenseMinor,
    );

    final dailyExpenseSeries = _denseDailySeries(
      monthStart: monthStart,
      dayValues: byDayExpense,
      daysInMonth: daysInMonth,
    );
    final dailyIncomeSeries = _denseDailySeries(
      monthStart: monthStart,
      dayValues: byDayIncome,
      daysInMonth: daysInMonth,
    );

    final topCategory = categories.isEmpty ? null : categories.first;
    final topSpendingDay = _resolveTopSpendingDay(dailyExpenseSeries, monthStart);
    final dailyAverageExpenseMinor =
        daysElapsed <= 0 ? 0 : (totalExpenseMinor / daysElapsed).round();

    final previousMonthStart = DateTime(year, month - 1, 1);
    final previousMonthEnd = DateTime(year, month, 1);
    final prevMonthExpense = await _expenses.sumBetween(
      startInclusive: previousMonthStart,
      endExclusive: previousMonthEnd,
    );

    final thisWeek = _currentWeekRange();
    final prevWeek = (
      start: thisWeek.start.subtract(const Duration(days: 7)),
      end: thisWeek.start,
    );
    final thisWeekExpense = await _expenses.sumBetween(
      startInclusive: thisWeek.start,
      endExclusive: thisWeek.end,
    );
    final prevWeekExpense = await _expenses.sumBetween(
      startInclusive: prevWeek.start,
      endExclusive: prevWeek.end,
    );

    final expenseComparisonVsPreviousMonth = ComparisonResult.from(
      currentMinor: totalExpenseMinor,
      previousMinor: prevMonthExpense,
    );
    final expenseComparisonVsPreviousWeek = ComparisonResult.from(
      currentMinor: thisWeekExpense,
      previousMinor: prevWeekExpense,
    );

    final insights = await _buildInsights(
      year: year,
      month: month,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
      prevMonthExpense: prevMonthExpense,
      topCategory: topCategory,
      topSpendingDay: topSpendingDay,
      weekComparison: expenseComparisonVsPreviousWeek,
      expenseSeries: dailyExpenseSeries,
    );

    return MonthlyReport(
      year: year,
      month: month,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
      transactionsCount: transactionsCount,
      dailyAverageExpenseMinor: dailyAverageExpenseMinor,
      topCategory: topCategory,
      topSpendingDay: topSpendingDay,
      categories: categories,
      dailyExpenseSeries: dailyExpenseSeries,
      dailyIncomeSeries: dailyIncomeSeries,
      expenseComparisonVsPreviousMonth: expenseComparisonVsPreviousMonth,
      expenseComparisonVsPreviousWeek: expenseComparisonVsPreviousWeek,
      insights: insights,
    );
  }

  @override
  Future<YearlyReport> yearlyReport({required int year}) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final byMonthExpense = await _expenses.sumByMonthBetween(
      startInclusive: start,
      endExclusive: end,
    );
    final byMonthIncome = await _incomes.sumByMonthBetween(
      startInclusive: start,
      endExclusive: end,
    );

    final months = <YearlyMonthSummary>[];
    final monthlyExpenseSeries = <TrendPoint>[];
    final monthlyIncomeSeries = <TrendPoint>[];
    var totalExpenseMinor = 0;
    var totalIncomeMinor = 0;

    for (var m = 1; m <= 12; m++) {
      final key = '${year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
      final expense = byMonthExpense[key] ?? 0;
      final income = byMonthIncome[key] ?? 0;
      totalExpenseMinor += expense;
      totalIncomeMinor += income;
      months.add(
        YearlyMonthSummary(
          year: year,
          month: m,
          totalIncomeMinor: income,
          totalExpenseMinor: expense,
        ),
      );
      monthlyExpenseSeries.add(
        TrendPoint(bucketKey: key, label: _monthLabels[m - 1], valueMinor: expense),
      );
      monthlyIncomeSeries.add(
        TrendPoint(bucketKey: key, label: _monthLabels[m - 1], valueMinor: income),
      );
    }

    final withExpense = months.where((e) => e.totalExpenseMinor > 0).toList(growable: false);
    YearlyMonthSummary? bestMonth;
    YearlyMonthSummary? worstMonth;
    if (withExpense.isNotEmpty) {
      bestMonth = withExpense.reduce(
        (a, b) => a.totalExpenseMinor <= b.totalExpenseMinor ? a : b,
      );
      worstMonth = withExpense.reduce(
        (a, b) => a.totalExpenseMinor >= b.totalExpenseMinor ? a : b,
      );
    }

    return YearlyReport(
      year: year,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
      months: months,
      bestMonth: bestMonth,
      worstMonth: worstMonth,
      monthlyExpenseSeries: monthlyExpenseSeries,
      monthlyIncomeSeries: monthlyIncomeSeries,
    );
  }

  @override
  Future<List<ReportInsight>> insightsForMonth({required int year, required int month}) async {
    final m = await monthlyReport(year: year, month: month);
    return m.insights;
  }

  Future<List<CategoryAnalysisItem>> _buildCategoryAnalysis({
    required Map<String, int> byCategory,
    required int totalExpenseMinor,
  }) async {
    if (byCategory.isEmpty || totalExpenseMinor <= 0) return const [];
    final categories = await _categories.getAll();
    final byId = {for (final c in categories) c.id: c};
    final out = <CategoryAnalysisItem>[];
    for (final entry in byCategory.entries) {
      final c = byId[entry.key];
      if (c == null || entry.value <= 0) continue;
      out.add(
        CategoryAnalysisItem(
          categoryId: c.id,
          name: c.name,
          iconKey: c.iconKey,
          colorValue: c.colorValue,
          amountMinor: entry.value,
          percent: (entry.value / totalExpenseMinor) * 100,
        ),
      );
    }
    out.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return out;
  }

  List<TrendPoint> _denseDailySeries({
    required DateTime monthStart,
    required Map<String, int> dayValues,
    required int daysInMonth,
  }) {
    final out = <TrendPoint>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(monthStart.year, monthStart.month, d);
      final key = _dayKeyFmt.format(date);
      out.add(
        TrendPoint(
          bucketKey: key,
          label: _dayLabelFmt.format(date),
          valueMinor: dayValues[key] ?? 0,
        ),
      );
    }
    return out;
  }

  TopSpendingDay? _resolveTopSpendingDay(List<TrendPoint> dailyExpenseSeries, DateTime monthStart) {
    if (dailyExpenseSeries.isEmpty) return null;
    final top = dailyExpenseSeries.reduce((a, b) => a.valueMinor >= b.valueMinor ? a : b);
    if (top.valueMinor <= 0) return null;
    final day = int.tryParse(top.label) ?? 1;
    return TopSpendingDay(
      day: DateTime(monthStart.year, monthStart.month, day),
      amountMinor: top.valueMinor,
    );
  }

  Future<List<ReportInsight>> _buildInsights({
    required int year,
    required int month,
    required int totalIncomeMinor,
    required int totalExpenseMinor,
    required int prevMonthExpense,
    required CategoryAnalysisItem? topCategory,
    required TopSpendingDay? topSpendingDay,
    required ComparisonResult weekComparison,
    required List<TrendPoint> expenseSeries,
  }) async {
    final out = <ReportInsight>[];
    final net = totalIncomeMinor - totalExpenseMinor;
    final prevMonthNet = await _previousMonthNet(year: year, month: month);

    if (topCategory != null && topCategory.percent >= 35) {
      out.add(
        ReportInsight(
          code: InsightCode.topCategoryHeavy,
          title: 'أعلى فئة صرف',
          message: 'أنت تصرف كثيراً على ${topCategory.name} (${topCategory.percent.toStringAsFixed(1)}%).',
          severity: InsightSeverity.warning,
        ),
      );
    }

    final monthCmp = ComparisonResult.from(
      currentMinor: totalExpenseMinor,
      previousMinor: prevMonthExpense,
    );
    if (monthCmp.deltaPct != null) {
      if ((monthCmp.deltaPct ?? 0) >= 10) {
        out.add(
          ReportInsight(
            code: InsightCode.monthOverMonthUp,
            title: 'مقارنة بالشهر الماضي',
            message: 'مصروفك زاد هذا الشهر بنسبة ${monthCmp.deltaPct!.toStringAsFixed(1)}%.',
            severity: InsightSeverity.warning,
          ),
        );
      } else if ((monthCmp.deltaPct ?? 0) <= -10) {
        out.add(
          ReportInsight(
            code: InsightCode.monthOverMonthDown,
            title: 'مقارنة بالشهر الماضي',
            message: 'مصروفك انخفض هذا الشهر بنسبة ${monthCmp.deltaPct!.abs().toStringAsFixed(1)}% — أحسنت!',
            severity: InsightSeverity.positive,
          ),
        );
      }
    }

    if (net < 0) {
      out.add(
        const ReportInsight(
          code: InsightCode.negativeSavings,
          title: 'تنبيه صافي مالي',
          message: 'مصاريفك تجاوزت دخلك هذا الشهر.',
          severity: InsightSeverity.warning,
        ),
      );
    } else if (net > 0 && net > prevMonthNet) {
      out.add(
        const ReportInsight(
          code: InsightCode.positiveSavings,
          title: 'تحسن مالي',
          message: 'وضعك المالي يتحسن هذا الشهر.',
          severity: InsightSeverity.positive,
        ),
      );
    }

    if (weekComparison.deltaPct != null) {
      if ((weekComparison.deltaPct ?? 0) > 0) {
        out.add(
          ReportInsight(
            code: InsightCode.weekOverWeekUp,
            title: 'مقارنة أسبوعية',
            message: 'صرفك هذا الأسبوع أعلى من الأسبوع الماضي بنسبة ${weekComparison.deltaPct!.toStringAsFixed(1)}%.',
            severity: InsightSeverity.warning,
          ),
        );
      } else if ((weekComparison.deltaPct ?? 0) < 0) {
        out.add(
          ReportInsight(
            code: InsightCode.weekOverWeekDown,
            title: 'مقارنة أسبوعية',
            message: 'صرفك هذا الأسبوع أقل من الأسبوع الماضي بنسبة ${weekComparison.deltaPct!.abs().toStringAsFixed(1)}%.',
            severity: InsightSeverity.positive,
          ),
        );
      }
    }

    if (topSpendingDay != null) {
      final dateLabel = DateFormat.yMMMMd('ar').format(topSpendingDay.day);
      out.add(
        ReportInsight(
          code: InsightCode.topSpendingDay,
          title: 'أعلى يوم صرف',
          message: 'أعلى يوم صرف كان $dateLabel.',
          severity: InsightSeverity.info,
        ),
      );
    } else if (expenseSeries.any((e) => e.valueMinor > 0)) {
      final top = expenseSeries.reduce((a, b) => a.valueMinor >= b.valueMinor ? a : b);
      out.add(
        ReportInsight(
          code: InsightCode.topSpendingDay,
          title: 'أعلى يوم صرف',
          message: 'أعلى يوم صرف في الشهر كان يوم ${top.label}.',
          severity: InsightSeverity.info,
        ),
      );
    }

    return out;
  }

  Future<int> _previousMonthNet({required int year, required int month}) async {
    final prevStart = DateTime(year, month - 1, 1);
    final prevEnd = DateTime(year, month, 1);
    final inc = await _incomes.sumBetween(
      startInclusive: prevStart,
      endExclusive: prevEnd,
    );
    final exp = await _expenses.sumBetween(
      startInclusive: prevStart,
      endExclusive: prevEnd,
    );
    return inc - exp;
  }

  ({DateTime start, DateTime end}) _currentWeekRange() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final shiftToMonday = (startOfToday.weekday - DateTime.monday) % 7;
    final start = startOfToday.subtract(Duration(days: shiftToMonday));
    final end = start.add(const Duration(days: 7));
    return (start: start, end: end);
  }

  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
}
