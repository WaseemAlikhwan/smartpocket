import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local/expense_local_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._local);

  final ExpenseLocalDataSource _local;

  ExpenseModel _asModel(ExpenseEntity e) => ExpenseModel(
    id: e.id,
    amountMinor: e.amountMinor,
    categoryId: e.categoryId,
    currencyCode: e.currencyCode,
    note: e.note,
    date: e.date,
    createdAt: e.createdAt,
  );

  @override
  Future<List<ExpenseEntity>> getAll() => _local.getAll();

  @override
  Future<List<ExpenseEntity>> getForMonth({required int year, required int month}) =>
      _local.getForMonth(year, month);

  @override
  Future<ExpenseEntity?> getById(String id) => _local.getById(id);

  @override
  Future<void> upsert(ExpenseEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<int> sumForMonth({required int year, required int month}) =>
      _local.sumForMonth(year, month);

  @override
  Future<Map<String, int>> sumByCategoryForMonth({
    required int year,
    required int month,
  }) => _local.sumByCategoryForMonth(year, month);

  @override
  Future<List<ExpenseEntity>> getForMonthByCategory({
    required int year,
    required int month,
    required String categoryId,
  }) => _local.getForMonthByCategory(
    year: year,
    month: month,
    categoryId: categoryId,
  );

  @override
  Future<int> sumBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumBetween(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );

  @override
  Future<int> sumForCategoryBetween({
    required String categoryId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumForCategoryBetween(
    categoryId: categoryId,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );

  @override
  Future<int> countBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.countBetween(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );

  @override
  Future<Map<String, int>> sumByCategoryBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumByCategoryBetween(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );

  @override
  Future<Map<String, int>> sumByDayBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumByDayBetween(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );

  @override
  Future<Map<String, int>> sumByMonthBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumByMonthBetween(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
}
