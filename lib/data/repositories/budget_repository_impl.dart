import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/local/budget_local_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._local);

  final BudgetLocalDataSource _local;

  BudgetModel _asModel(BudgetEntity e) => BudgetModel(
    id: e.id,
    categoryId: e.categoryId,
    year: e.year,
    month: e.month,
    limitAmountMinor: e.limitAmountMinor,
    alertPeriod: e.alertPeriod,
    createdAt: e.createdAt,
  );

  @override
  Future<List<BudgetEntity>> getForMonth({required int year, required int month}) =>
      _local.getForMonth(year, month);

  @override
  Future<BudgetEntity?> getForCategoryMonth({
    required String categoryId,
    required int year,
    required int month,
  }) => _local.getForCategoryMonth(
    categoryId: categoryId,
    year: year,
    month: month,
  );

  @override
  Future<void> upsert(BudgetEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<int> sumLimitsForMonth({required int year, required int month}) =>
      _local.sumLimitsForMonth(year, month);
}
