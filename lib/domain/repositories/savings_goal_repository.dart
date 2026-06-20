import '../entities/savings_goal_entity.dart';
import '../entities/saving_goal_contribution_entity.dart';

abstract class SavingsGoalRepository {
  Future<List<SavingsGoalEntity>> getAll();
  Future<SavingsGoalEntity?> getById(String id);
  Future<void> upsert(SavingsGoalEntity entity);
  Future<void> delete(String id);

  /// Adds a new saving contribution to [id].
  Future<void> addContribution({
    required String id,
    required int amountMinor,
    required SavingContributionSource source,
    String? linkedExpenseId,
    required DateTime paidAt,
  });

  Future<List<SavingGoalContributionEntity>> listContributions(String goalId);

  Future<void> updateContribution({
    required String contributionId,
    required int amountMinor,
    required SavingContributionSource source,
    String? linkedExpenseId,
    required DateTime updatedAt,
  });

  Future<void> deleteContribution(String contributionId);
}
