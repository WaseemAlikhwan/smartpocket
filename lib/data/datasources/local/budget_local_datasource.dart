import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../models/budget_model.dart';

class BudgetLocalDataSource {
  BudgetLocalDataSource(this._db);

  final Database _db;

  Future<List<BudgetModel>> getForMonth(int year, int month) async {
    final rows = await _db.query(
      DbConstants.tableBudgets,
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return rows.map(BudgetModel.fromRow).toList();
  }

  Future<BudgetModel?> getForCategoryMonth({
    required String categoryId,
    required int year,
    required int month,
  }) async {
    final rows = await _db.query(
      DbConstants.tableBudgets,
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [categoryId, year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetModel.fromRow(rows.single);
  }

  Future<int> sumLimitsForMonth(int year, int month) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(limit_amount_minor), 0) AS s
      FROM ${DbConstants.tableBudgets}
      WHERE year = ? AND month = ?
      ''',
      [year, month],
    );
    return (result.first['s'] as num?)?.toInt() ?? 0;
  }

  Future<void> insertOrReplace(BudgetModel model) async {
    await _db.insert(
      DbConstants.tableBudgets,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableBudgets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    await _db.delete(DbConstants.tableBudgets);
  }

  Future<void> insertAll(List<BudgetModel> list) async {
    final batch = _db.batch();
    for (final m in list) {
      batch.insert(
        DbConstants.tableBudgets,
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
