import '../entities/recurring_entry_entity.dart';

abstract class RecurringRepository {
  Future<List<RecurringEntryEntity>> getAll();
  Future<List<RecurringEntryEntity>> getActive();
  Future<RecurringEntryEntity?> getById(String id);
  Future<void> upsert(RecurringEntryEntity entity);
  Future<void> delete(String id);
  Future<void> updateLastConfirmedYm(String id, String ym);
}
