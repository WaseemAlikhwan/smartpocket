import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/local/debt_local_datasource.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._local);

  final DebtLocalDataSource _local;

  DebtModel _asModel(DebtEntity e) => DebtModel(
    id: e.id,
    amountMinor: e.amountMinor,
    paidAmountMinor: e.paidAmountMinor,
    remainingAmountMinor: e.remainingAmountMinor,
    currencyCode: e.currencyCode,
    personName: e.personName,
    contactId: e.contactId,
    dueDate: e.dueDate,
    type: e.type,
    status: e.status,
    lastPaymentAt: e.lastPaymentAt,
    reminderLastSentAt: e.reminderLastSentAt,
    note: e.note,
    createdAt: e.createdAt,
  );

  @override
  Future<List<DebtEntity>> getAll() => _local.getAll();

  @override
  Future<List<DebtEntity>> getPendingDebts() => _local.getPendingDebts();

  @override
  Future<List<DebtEntity>> getSettledForMonth({required int year, required int month}) =>
      _local.getSettledForMonth(year, month);

  @override
  Future<List<DebtEntity>> getByType(DebtType type) => _local.getByType(type);

  @override
  Future<List<DebtEntity>> getDebtsNeedingReminder({required DateTime now}) =>
      _local.getDebtsNeedingReminder(now: now);

  @override
  Future<DebtEntity?> getById(String id) => _local.getById(id);

  @override
  Future<void> upsert(DebtEntity entity) => _local.insertOrReplace(_asModel(entity));

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> markPayment({
    required String id,
    required int paidAmountMinor,
    DateTime? paidAt,
  }) => _local.markPayment(
    id: id,
    paidAmountMinor: paidAmountMinor,
    paidAt: paidAt ?? DateTime.now().toUtc(),
  );

  @override
  Future<void> markPaid(String id, {DateTime? paidAt}) =>
      _local.markPaid(id, paidAt: paidAt ?? DateTime.now().toUtc());

  @override
  Future<void> markReminderSent(String id, DateTime at) =>
      _local.markReminderSent(id, at);

  @override
  Future<List<DebtPaymentEntity>> getPaymentsForDebt(String debtId) =>
      _local.getPaymentsForDebt(debtId);
}
