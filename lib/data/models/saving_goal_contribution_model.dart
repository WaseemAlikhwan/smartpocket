import '../../core/constants/db_constants.dart';
import '../../domain/entities/saving_goal_contribution_entity.dart';

class SavingGoalContributionModel extends SavingGoalContributionEntity {
  const SavingGoalContributionModel({
    required super.id,
    required super.goalId,
    required super.amountMinor,
    required super.source,
    required super.createdAt,
    required super.updatedAt,
    super.linkedExpenseId,
  });

  static SavingContributionSource _sourceFrom(String? raw) {
    switch (raw) {
      case 'from_balance':
        return SavingContributionSource.fromBalance;
      case 'external':
      default:
        return SavingContributionSource.external;
    }
  }

  static String _sourceTo(SavingContributionSource source) {
    switch (source) {
      case SavingContributionSource.fromBalance:
        return 'from_balance';
      case SavingContributionSource.external:
        return 'external';
    }
  }

  factory SavingGoalContributionModel.fromRow(Map<String, Object?> map) {
    return SavingGoalContributionModel(
      id: map['id']! as String,
      goalId: map['goal_id']! as String,
      amountMinor: map['amount_minor']! as int,
      source: _sourceFrom(map['source'] as String?),
      linkedExpenseId: map['linked_expense_id'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'goal_id': goalId,
    'amount_minor': amountMinor,
    'source': _sourceTo(source),
    'linked_expense_id': linkedExpenseId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableSavingsGoalContributions;
}
