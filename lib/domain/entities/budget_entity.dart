import '../value_objects/budget_alert_period.dart';

class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitAmountMinor,
    required this.alertPeriod,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final int year;
  final int month;
  final int limitAmountMinor;
  final BudgetAlertPeriod alertPeriod;
  final DateTime createdAt;
}
