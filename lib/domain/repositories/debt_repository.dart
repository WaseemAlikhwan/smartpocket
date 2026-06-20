import '../entities/debt_entity.dart';
import '../entities/debt_payment_entity.dart';

abstract class DebtRepository {
  Future<List<DebtEntity>> getAll();
  Future<List<DebtEntity>> getPendingDebts();
  Future<List<DebtEntity>> getSettledForMonth({required int year, required int month});
  Future<List<DebtEntity>> getByType(DebtType type);
  Future<List<DebtEntity>> getDebtsNeedingReminder({required DateTime now});
  Future<DebtEntity?> getById(String id);
  Future<void> upsert(DebtEntity entity);
  Future<void> delete(String id);
  Future<void> markPayment({
    required String id,
    required int paidAmountMinor,
    DateTime? paidAt,
  });
  Future<void> markPaid(String id, {DateTime? paidAt});
  Future<void> markReminderSent(String id, DateTime at);
  Future<List<DebtPaymentEntity>> getPaymentsForDebt(String debtId);
}
