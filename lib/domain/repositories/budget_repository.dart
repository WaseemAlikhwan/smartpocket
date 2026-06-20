import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<List<BudgetEntity>> getForMonth({required int year, required int month});
  Future<BudgetEntity?> getForCategoryMonth({
    required String categoryId,
    required int year,
    required int month,
  });
  Future<void> upsert(BudgetEntity entity);
  Future<void> delete(String id);

  /// Sum of [limit_amount_minor] for all budgets registered for [year]/[month].
  Future<int> sumLimitsForMonth({required int year, required int month});
}
