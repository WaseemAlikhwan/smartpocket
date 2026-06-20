import '../../domain/value_objects/budget_alert_period.dart';

int daysInCalendarMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day;

DateTime localStartOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day);

/// Monday-start week containing [day] (local calendar).
DateTime mondayOfWeekContaining(DateTime day) {
  final s = localStartOfDay(day);
  return s.subtract(Duration(days: s.weekday - DateTime.monday));
}

({DateTime startInclusive, DateTime endExclusive}) localDayRange(
  DateTime day,
) {
  final s = localStartOfDay(day);
  return (startInclusive: s, endExclusive: s.add(const Duration(days: 1)));
}

/// Intersection of [weekStart, weekStart+7) with [monthStart, monthEnd).
({DateTime startInclusive, DateTime endExclusive}) weekRangeInMonth({
  required DateTime anchorDay,
  required int year,
  required int month,
}) {
  final monthStart = DateTime(year, month, 1);
  final monthEnd = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  final weekStart = mondayOfWeekContaining(anchorDay);
  final weekEnd = weekStart.add(const Duration(days: 7));
  var start = weekStart.isBefore(monthStart) ? monthStart : weekStart;
  var end = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
  if (!start.isBefore(end)) {
    start = monthStart;
    end = monthEnd;
  }
  return (startInclusive: start, endExclusive: end);
}

Future<bool> isCategoryBudgetOverrun({
  required BudgetAlertPeriod period,
  required int year,
  required int month,
  required String categoryId,
  required int categoryLimitMinor,
  required int spentThisMonthMinor,
  required Future<int> Function(String categoryId, DateTime start, DateTime end)
      sumCategoryBetween,
}) async {
  if (categoryLimitMinor <= 0) return false;

  final dim = daysInCalendarMonth(year, month);
  final now = DateTime.now();
  final viewingCurrentMonth = now.year == year && now.month == month;

  final BudgetAlertPeriod effective =
      (!viewingCurrentMonth && period != BudgetAlertPeriod.month)
          ? BudgetAlertPeriod.month
          : period;

  switch (effective) {
    case BudgetAlertPeriod.month:
      return spentThisMonthMinor > categoryLimitMinor;
    case BudgetAlertPeriod.day:
      final dr = localDayRange(now);
      final spent = await sumCategoryBetween(
        categoryId,
        dr.startInclusive,
        dr.endExclusive,
      );
      final dailyCap = (categoryLimitMinor + dim - 1) ~/ dim;
      return spent > dailyCap;
    case BudgetAlertPeriod.week:
      final w = weekRangeInMonth(anchorDay: now, year: year, month: month);
      final spent = await sumCategoryBetween(
        categoryId,
        w.startInclusive,
        w.endExclusive,
      );
      final weekCap = (categoryLimitMinor * 7 + dim - 1) ~/ dim;
      return spent > weekCap;
  }
}

/// Compares total spending to prorated monthly budget caps.
Future<bool> isBudgetOverrun({
  required BudgetAlertPeriod period,
  required int year,
  required int month,
  required int budgetCapSumMinor,
  required int totalSpentMonthMinor,
  required Future<int> Function(DateTime start, DateTime end) sumExpensesBetween,
}) async {
  if (budgetCapSumMinor <= 0) return false;

  final dim = daysInCalendarMonth(year, month);
  final now = DateTime.now();
  final viewingCurrentMonth = now.year == year && now.month == month;

  BudgetAlertPeriod effective = period;
  if (!viewingCurrentMonth &&
      period != BudgetAlertPeriod.month) {
    effective = BudgetAlertPeriod.month;
  }

  switch (effective) {
    case BudgetAlertPeriod.month:
      return totalSpentMonthMinor > budgetCapSumMinor;
    case BudgetAlertPeriod.day:
      final day = localDayRange(now);
      final spent = await sumExpensesBetween(day.startInclusive, day.endExclusive);
      final dailyCap = (budgetCapSumMinor + dim - 1) ~/ dim;
      return spent > dailyCap;
    case BudgetAlertPeriod.week:
      final w = weekRangeInMonth(anchorDay: now, year: year, month: month);
      final spent = await sumExpensesBetween(w.startInclusive, w.endExclusive);
      final weekCap = (budgetCapSumMinor * 7 + dim - 1) ~/ dim;
      return spent > weekCap;
  }
}
