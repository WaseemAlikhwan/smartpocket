import '../../core/constants/db_constants.dart';
import '../../domain/entities/savings_goal_entity.dart';

class SavingsGoalModel extends SavingsGoalEntity {
  const SavingsGoalModel({
    required super.id,
    required super.title,
    required super.targetAmountMinor,
    required super.savedAmountMinor,
    required super.startDate,
    required super.targetDate,
    required super.status,
    required super.currencyCode,
    required super.createdAt,
    required super.updatedAt,
  });

  static SavingsGoalStatus _statusFromStorage(String? raw) {
    switch (raw) {
      case 'completed':
        return SavingsGoalStatus.completed;
      case 'active':
      default:
        return SavingsGoalStatus.active;
    }
  }

  static String _statusToStorage(SavingsGoalStatus status) {
    switch (status) {
      case SavingsGoalStatus.completed:
        return 'completed';
      case SavingsGoalStatus.active:
        return 'active';
    }
  }

  factory SavingsGoalModel.fromRow(Map<String, Object?> map) {
    return SavingsGoalModel(
      id: map['id']! as String,
      title: map['title']! as String,
      targetAmountMinor: map['target_amount_minor']! as int,
      savedAmountMinor: map['saved_amount_minor']! as int,
      startDate: DateTime.parse(map['start_date']! as String),
      targetDate: DateTime.parse(map['target_date']! as String),
      status: _statusFromStorage(map['status'] as String?),
      currencyCode: (map['currency_code'] as String?) ?? 'SYP',
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'target_amount_minor': targetAmountMinor,
        'saved_amount_minor': savedAmountMinor,
        'start_date': startDate.toUtc().toIso8601String(),
        'target_date': targetDate.toUtc().toIso8601String(),
        'status': _statusToStorage(status),
        'currency_code': currencyCode,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  static String get table => DbConstants.tableSavingsGoals;
}
