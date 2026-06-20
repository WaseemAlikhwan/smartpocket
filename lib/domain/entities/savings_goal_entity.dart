enum SavingsGoalStatus { active, completed }

class SavingsGoalEntity {
  const SavingsGoalEntity({
    required this.id,
    required this.title,
    required this.targetAmountMinor,
    required this.savedAmountMinor,
    required this.startDate,
    required this.targetDate,
    required this.status,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int targetAmountMinor;
  final int savedAmountMinor;
  final DateTime startDate;
  final DateTime targetDate;
  final SavingsGoalStatus status;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
