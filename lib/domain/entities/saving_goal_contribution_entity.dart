enum SavingContributionSource { fromBalance, external }

class SavingGoalContributionEntity {
  const SavingGoalContributionEntity({
    required this.id,
    required this.goalId,
    required this.amountMinor,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.linkedExpenseId,
  });

  final String id;
  final String goalId;
  final int amountMinor;
  final SavingContributionSource source;
  final String? linkedExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
