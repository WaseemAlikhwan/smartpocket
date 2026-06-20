import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<SettingsEntity?> get();
  Future<void> upsert(SettingsEntity entity);
}
