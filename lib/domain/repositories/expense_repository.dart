import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getAll();
  Future<List<ExpenseEntity>> getForMonth({required int year, required int month});
  Future<ExpenseEntity?> getById(String id);
  Future<void> upsert(ExpenseEntity entity);
  Future<void> delete(String id);

  Future<int> sumForMonth({required int year, required int month});

  Future<Map<String, int>> sumByCategoryForMonth({
    required int year,
    required int month,
  });

  Future<List<ExpenseEntity>> getForMonthByCategory({
    required int year,
    required int month,
    required String categoryId,
  });

  /// Total spent in `[startInclusive, endExclusive)`.
  Future<int> sumBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<int> sumForCategoryBetween({
    required String categoryId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<int> countBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<Map<String, int>> sumByCategoryBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<Map<String, int>> sumByDayBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<Map<String, int>> sumByMonthBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
