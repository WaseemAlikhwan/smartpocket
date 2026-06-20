import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  SettingsModel _asModel(SettingsEntity e) => SettingsModel(
    id: e.id,
    openingBalanceMinor: e.openingBalanceMinor,
    defaultMonthlyIncomeMinor: e.defaultMonthlyIncomeMinor,
    baseCurrencyCode: e.baseCurrencyCode,
    onboardingCompleted: e.onboardingCompleted,
    budgetAlertPeriod: e.budgetAlertPeriod,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  @override
  Future<SettingsEntity?> get() => _local.get();

  @override
  Future<void> upsert(SettingsEntity entity) => _local.upsert(_asModel(entity));
}
