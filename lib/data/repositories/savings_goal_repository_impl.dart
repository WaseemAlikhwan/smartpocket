import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/saving_goal_contribution_entity.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../datasources/local/savings_goal_local_datasource.dart';
import '../models/saving_goal_contribution_model.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  SavingsGoalRepositoryImpl(this._local);

  final SavingsGoalLocalDataSource _local;

  SavingsGoalModel _m(SavingsGoalEntity e) => SavingsGoalModel(
        id: e.id,
        title: e.title,
        targetAmountMinor: e.targetAmountMinor,
        savedAmountMinor: e.savedAmountMinor,
        startDate: e.startDate,
        targetDate: e.targetDate,
        status: e.status,
        currencyCode: e.currencyCode,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  @override
  Future<List<SavingsGoalEntity>> getAll() async {
    final rows = await _local.getAll();
    return List<SavingsGoalEntity>.from(rows);
  }

  @override
  Future<SavingsGoalEntity?> getById(String id) => _local.getById(id);

  @override
  Future<void> upsert(SavingsGoalEntity entity) =>
      _local.insertOrReplace(_m(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> addContribution({
    required String id,
    required int amountMinor,
    required SavingContributionSource source,
    String? linkedExpenseId,
    required DateTime paidAt,
  }) async {
    if (amountMinor <= 0) return;
    final now = paidAt.toUtc();
    await _local.insertContribution(
      SavingGoalContributionModel(
        id: '${id}_${now.microsecondsSinceEpoch}',
        goalId: id,
        amountMinor: amountMinor,
        source: source,
        linkedExpenseId: linkedExpenseId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _recomputeGoal(id, now);
  }

  @override
  Future<List<SavingGoalContributionEntity>> listContributions(String goalId) async {
    final rows = await _local.listContributions(goalId);
    return List<SavingGoalContributionEntity>.from(rows);
  }

  @override
  Future<void> updateContribution({
    required String contributionId,
    required int amountMinor,
    required SavingContributionSource source,
    String? linkedExpenseId,
    required DateTime updatedAt,
  }) async {
    final old = await _local.getContributionById(contributionId);
    if (old == null) return;
    final next = SavingGoalContributionModel(
      id: old.id,
      goalId: old.goalId,
      amountMinor: amountMinor,
      source: source,
      linkedExpenseId: linkedExpenseId,
      createdAt: old.createdAt,
      updatedAt: updatedAt.toUtc(),
    );
    await _local.updateContribution(next);
    await _recomputeGoal(old.goalId, updatedAt.toUtc());
  }

  @override
  Future<void> deleteContribution(String contributionId) async {
    final old = await _local.getContributionById(contributionId);
    if (old == null) return;
    await _local.deleteContribution(contributionId);
    await _recomputeGoal(old.goalId, DateTime.now().toUtc());
  }

  Future<void> _recomputeGoal(String goalId, DateTime nowUtc) async {
    final goal = await _local.getById(goalId);
    if (goal == null) return;
    final list = await _local.listContributions(goalId);
    final saved = list.fold<int>(0, (s, e) => s + e.amountMinor);
    final status = saved >= goal.targetAmountMinor
        ? SavingsGoalStatus.completed
        : SavingsGoalStatus.active;
    await _local.insertOrReplace(
      SavingsGoalModel(
        id: goal.id,
        title: goal.title,
        targetAmountMinor: goal.targetAmountMinor,
        savedAmountMinor: saved,
        startDate: goal.startDate,
        targetDate: goal.targetDate,
        status: status,
        currencyCode: goal.currencyCode,
        createdAt: goal.createdAt,
        updatedAt: nowUtc,
      ),
    );
  }
}
