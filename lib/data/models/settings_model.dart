import '../../core/constants/db_constants.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';

class SettingsModel extends SettingsEntity {
  const SettingsModel({
    required super.id,
    required super.openingBalanceMinor,
    required super.defaultMonthlyIncomeMinor,
    required super.baseCurrencyCode,
    required super.onboardingCompleted,
    required super.budgetAlertPeriod,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SettingsModel.fromRow(Map<String, Object?> map) {
    return SettingsModel(
      id: map['id']! as String,
      openingBalanceMinor: map['opening_balance_minor']! as int,
      defaultMonthlyIncomeMinor: map['default_monthly_income_minor']! as int,
      baseCurrencyCode: map['base_currency_code']! as String,
      onboardingCompleted: (map['onboarding_completed']! as int) == 1,
      budgetAlertPeriod: budgetAlertPeriodFromStorage(
        map['budget_alert_period'] as String?,
      ),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'opening_balance_minor': openingBalanceMinor,
    'default_monthly_income_minor': defaultMonthlyIncomeMinor,
    'base_currency_code': baseCurrencyCode,
    'onboarding_completed': onboardingCompleted ? 1 : 0,
    'budget_alert_period': budgetAlertPeriod.storageValue,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableSettings;
}
