import '../../core/constants/db_constants.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.categoryId,
    required super.year,
    required super.month,
    required super.limitAmountMinor,
    required super.alertPeriod,
    required super.createdAt,
  });

  factory BudgetModel.fromRow(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id']! as String,
      categoryId: map['category_id']! as String,
      year: map['year']! as int,
      month: map['month']! as int,
      limitAmountMinor: map['limit_amount_minor']! as int,
      alertPeriod: budgetAlertPeriodFromStorage(map['alert_period'] as String?),
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'category_id': categoryId,
    'year': year,
    'month': month,
    'limit_amount_minor': limitAmountMinor,
    'alert_period': alertPeriod.storageValue,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableBudgets;
}
