import '../value_objects/budget_alert_period.dart';

class SettingsEntity {
  const SettingsEntity({
    required this.id,
    required this.openingBalanceMinor,
    required this.defaultMonthlyIncomeMinor,
    required this.baseCurrencyCode,
    required this.onboardingCompleted,
    required this.budgetAlertPeriod,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int openingBalanceMinor;
  final int defaultMonthlyIncomeMinor;
  final String baseCurrencyCode;
  final bool onboardingCompleted;
  final BudgetAlertPeriod budgetAlertPeriod;
  final DateTime createdAt;
  final DateTime updatedAt;
}
