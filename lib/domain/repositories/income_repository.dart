import '../entities/income_entity.dart';

abstract class IncomeRepository {
  Future<List<IncomeEntity>> getAll();
  Future<List<IncomeEntity>> getForMonth({required int year, required int month});
  Future<IncomeEntity?> getById(String id);
  Future<void> upsert(IncomeEntity entity);
  Future<void> delete(String id);
  Future<int> sumForMonth({required int year, required int month});
  Future<int> sumBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
  Future<int> countBetween({
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
