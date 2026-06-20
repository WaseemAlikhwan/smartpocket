import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../models/recurring_entry_model.dart';

class RecurringLocalDataSource {
  RecurringLocalDataSource(this._db);

  final Database _db;

  Future<List<RecurringEntryModel>> getAll() async {
    final rows = await _db.query(DbConstants.tableRecurringEntries, orderBy: 'created_at DESC');
    return rows.map(RecurringEntryModel.fromRow).toList();
  }

  Future<List<RecurringEntryModel>> getActive() async {
    final rows = await _db.query(
      DbConstants.tableRecurringEntries,
      where: 'is_active = 1',
      orderBy: 'day_of_month ASC',
    );
    return rows.map(RecurringEntryModel.fromRow).toList();
  }

  Future<RecurringEntryModel?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableRecurringEntries,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecurringEntryModel.fromRow(rows.single);
  }

  Future<void> insertOrReplace(RecurringEntryModel model) async {
    await _db.insert(
      DbConstants.tableRecurringEntries,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(DbConstants.tableRecurringEntries, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateLastConfirmedYm(String id, String ym) async {
    await _db.update(
      DbConstants.tableRecurringEntries,
      {'last_confirmed_ym': ym},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
