import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/debt_entity.dart';
import '../../../domain/entities/debt_payment_entity.dart';
import '../../models/debt_model.dart';

class DebtLocalDataSource {
  DebtLocalDataSource(this._db);

  final Database _db;
  final _uuid = const Uuid();

  DateTime _utcStartOfMonth(int year, int month) => DateTime.utc(year, month, 1);

  DateTime _utcEndExclusive(int year, int month) =>
      month == 12 ? DateTime.utc(year + 1, 1, 1) : DateTime.utc(year, month + 1, 1);

  Future<List<DebtModel>> getAll() async {
    final rows = await _db.query(DbConstants.tableDebts, orderBy: 'due_date ASC');
    return rows.map(DebtModel.fromRow).toList();
  }

  Future<List<DebtModel>> getPendingDebts() async {
    final rows = await _db.query(
      DbConstants.tableDebts,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'due_date ASC',
    );
    return rows.map(DebtModel.fromRow).toList();
  }

  Future<List<DebtModel>> getByType(DebtType type) async {
    final rawType = type == DebtType.owedToMe ? 'owed_to_me' : 'owed_by_me';
    final rows = await _db.query(
      DbConstants.tableDebts,
      where: 'debt_type = ?',
      whereArgs: [rawType],
      orderBy: 'due_date ASC',
    );
    return rows.map(DebtModel.fromRow).toList();
  }

  Future<List<DebtModel>> getSettledForMonth(int year, int month) async {
    final start = _utcStartOfMonth(year, month).toIso8601String();
    final end = _utcEndExclusive(year, month).toIso8601String();
    final rows = await _db.query(
      DbConstants.tableDebts,
      where: 'last_payment_at >= ? AND last_payment_at < ?',
      whereArgs: [start, end],
      orderBy: 'last_payment_at DESC',
    );
    return rows.map(DebtModel.fromRow).toList();
  }

  Future<DebtModel?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DebtModel.fromRow(rows.single);
  }

  Future<void> insertOrReplace(DebtModel model) async {
    await _db.insert(
      DbConstants.tableDebts,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(DbConstants.tableDebts, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPayment({
    required String id,
    required int paidAmountMinor,
    required DateTime paidAt,
  }) async {
    final row = await getById(id);
    if (row == null) return;
    final nextPaid = (row.paidAmountMinor + paidAmountMinor).clamp(0, row.amountMinor);
    final appliedMinor = nextPaid - row.paidAmountMinor;
    if (appliedMinor <= 0) return;
    final remaining = row.amountMinor - nextPaid;
    await _db.update(
      DbConstants.tableDebts,
      {
        'paid_amount_minor': nextPaid,
        'remaining_amount_minor': remaining,
        'status': remaining <= 0 ? 'paid' : 'pending',
        'last_payment_at': paidAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.insert(DbConstants.tableDebtPayments, {
      'id': _uuid.v4(),
      'debt_id': id,
      'amount_minor': appliedMinor,
      'paid_at': paidAt.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> markPaid(String id, {required DateTime paidAt}) async {
    final row = await getById(id);
    if (row == null) return;
    await _db.update(
      DbConstants.tableDebts,
      {
        'paid_amount_minor': row.amountMinor,
        'remaining_amount_minor': 0,
        'status': 'paid',
        'last_payment_at': paidAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.insert(DbConstants.tableDebtPayments, {
      'id': _uuid.v4(),
      'debt_id': id,
      'amount_minor': row.remainingAmountMinor <= 0 ? row.amountMinor : row.remainingAmountMinor,
      'paid_at': paidAt.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<DebtModel>> getDebtsNeedingReminder({required DateTime now}) async {
    final dayStart = DateTime.utc(now.year, now.month, now.day).toIso8601String();
    final dueThreshold = DateTime.utc(now.year, now.month, now.day + 1).toIso8601String();
    final rows = await _db.query(
      DbConstants.tableDebts,
      where:
          'status = ? AND due_date <= ? AND (reminder_last_sent_at IS NULL OR reminder_last_sent_at < ?)',
      whereArgs: ['pending', dueThreshold, dayStart],
      orderBy: 'due_date ASC',
    );
    return rows.map(DebtModel.fromRow).toList();
  }

  Future<void> markReminderSent(String id, DateTime at) async {
    await _db.update(
      DbConstants.tableDebts,
      {
        'reminder_last_sent_at': at.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DebtPaymentEntity>> getPaymentsForDebt(String debtId) async {
    final rows = await _db.query(
      DbConstants.tableDebtPayments,
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'paid_at DESC, created_at DESC',
    );
    return rows
        .map(
          (m) => DebtPaymentEntity(
            id: m['id']! as String,
            debtId: m['debt_id']! as String,
            amountMinor: m['amount_minor']! as int,
            paidAt: DateTime.parse(m['paid_at']! as String),
            createdAt: DateTime.parse(m['created_at']! as String),
          ),
        )
        .toList();
  }
}
