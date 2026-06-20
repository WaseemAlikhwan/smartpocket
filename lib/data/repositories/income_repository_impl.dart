import '../../domain/entities/income_entity.dart';
import '../../domain/repositories/income_repository.dart';
import '../datasources/local/income_local_datasource.dart';
import '../models/income_model.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  IncomeRepositoryImpl(this._local);

  final IncomeLocalDataSource _local;

  IncomeModel _asModel(IncomeEntity e) => IncomeModel(
    id: e.id,
    amountMinor: e.amountMinor,
    currencyCode: e.currencyCode,
    date: e.date,
    source: e.source,
    createdAt: e.createdAt,
  );

  @override
  Future<List<IncomeEntity>> getAll() => _local.getAll();

  @override
  Future<List<IncomeEntity>> getForMonth({required int year, required int month}) =>
      _local.getForMonth(year, month);

  @override
  Future<IncomeEntity?> getById(String id) => _local.getById(id);

  @override
  Future<void> upsert(IncomeEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<int> sumForMonth({required int year, required int month}) =>
      _local.sumForMonth(year, month);

  @override
  Future<int> sumBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _local.sumBetween(
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
