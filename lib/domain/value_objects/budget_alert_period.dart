/// How the app compares spending to the **monthly** budget cap for warnings.
enum BudgetAlertPeriod {
  /// Full month total vs sum of category monthly limits.
  month,

  /// Current calendar week (Mon–Sun), clipped to the selected month, vs prorated cap.
  week,

  /// Current calendar day vs daily share of the monthly cap (cap ÷ days in month).
  day,
}

extension BudgetAlertPeriodStorage on BudgetAlertPeriod {
  String get storageValue {
    switch (this) {
      case BudgetAlertPeriod.month:
        return 'month';
      case BudgetAlertPeriod.week:
        return 'week';
      case BudgetAlertPeriod.day:
        return 'day';
    }
  }
}

BudgetAlertPeriod budgetAlertPeriodFromStorage(String? v) {
  switch (v) {
    case 'week':
      return BudgetAlertPeriod.week;
    case 'day':
      return BudgetAlertPeriod.day;
    case 'month':
    default:
      return BudgetAlertPeriod.month;
  }
}
