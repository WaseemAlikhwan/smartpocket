import '../../domain/entities/recurring_entry_entity.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../datasources/local/recurring_local_datasource.dart';
import '../models/recurring_entry_model.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._local);

  final RecurringLocalDataSource _local;

  RecurringEntryModel _asModel(RecurringEntryEntity e) => RecurringEntryModel(
    id: e.id,
    entryKind: e.entryKind,
    title: e.title,
    amountMinor: e.amountMinor,
    currencyCode: e.currencyCode,
    dayOfMonth: e.dayOfMonth,
    isActive: e.isActive,
    payloadJson: e.payloadJson,
    lastConfirmedYm: e.lastConfirmedYm,
    createdAt: e.createdAt,
  );

  @override
  Future<List<RecurringEntryEntity>> getAll() => _local.getAll();

  @override
  Future<List<RecurringEntryEntity>> getActive() => _local.getActive();

  @override
  Future<RecurringEntryEntity?> getById(String id) => _local.getById(id);

  @override
  Future<void> upsert(RecurringEntryEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> updateLastConfirmedYm(String id, String ym) => _local.updateLastConfirmedYm(id, ym);
}
