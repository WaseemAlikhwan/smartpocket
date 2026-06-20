import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../models/income_model.dart';

class IncomeLocalDataSource {
  IncomeLocalDataSource(this._db);

  final Database _db;

  DateTime _utcStartOfMonth(int year, int month) =>
      DateTime.utc(year, month, 1);

  DateTime _utcEndExclusive(int year, int month) =>
      month == 12
          ? DateTime.utc(year + 1, 1, 1)
          : DateTime.utc(year, month + 1, 1);

  Future<List<IncomeModel>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableIncomes,
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(IncomeModel.fromRow).toList();
  }

  Future<IncomeModel?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableIncomes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IncomeModel.fromRow(rows.single);
  }

  Future<List<IncomeModel>> getForMonth(int year, int month) async {
    final start = _utcStartOfMonth(year, month).toIso8601String();
    final end = _utcEndExclusive(year, month).toIso8601String();
    final rows = await _db.query(
      DbConstants.tableIncomes,
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(IncomeModel.fromRow).toList();
  }

  Future<List<IncomeModel>> getBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final a = startInclusive.toUtc().toIso8601String();
    final b = endExclusive.toUtc().toIso8601String();
    final rows = await _db.query(
      DbConstants.tableIncomes,
      where: 'date >= ? AND date < ?',
      whereArgs: [a, b],
      orderBy: 'date ASC, created_at ASC',
    );
    return rows.map(IncomeModel.fromRow).toList();
  }

  Future<int> sumForMonth(int year, int month) async {
    final start = _utcStartOfMonth(year, month).toIso8601String();
    final end = _utcEndExclusive(year, month).toIso8601String();
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_minor), 0) AS s
      FROM ${DbConstants.tableIncomes}
      WHERE date >= ? AND date < ?
      ''',
      [start, end],
    );
    return (result.first['s'] as num?)?.toInt() ?? 0;
  }

  Future<int> sumBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final a = startInclusive.toUtc().toIso8601String();
    final b = endExclusive.toUtc().toIso8601String();
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_minor), 0) AS s
      FROM ${DbConstants.tableIncomes}
      WHERE date >= ? AND date < ?
      ''',
      [a, b],
    );
    return (result.first['s'] as num?)?.toInt() ?? 0;
  }

  Future<int> countBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final a = startInclusive.toUtc().toIso8601String();
    final b = endExclusive.toUtc().toIso8601String();
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM ${DbConstants.tableIncomes}
      WHERE date >= ? AND date < ?
      ''',
      [a, b],
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, int>> sumByDayBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final a = startInclusive.toUtc().toIso8601String();
    final b = endExclusive.toUtc().toIso8601String();
    final rows = await _db.rawQuery(
      '''
      SELECT substr(datetime(date, 'localtime'), 1, 10) AS day_key,
             COALESCE(SUM(amount_minor), 0) AS s
      FROM ${DbConstants.tableIncomes}
      WHERE date >= ? AND date < ?
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      [a, b],
    );
    final out = <String, int>{};
    for (final r in rows) {
      final key = r['day_key'] as String?;
      if (key == null || key.isEmpty) continue;
      out[key] = (r['s'] as num?)?.toInt() ?? 0;
    }
    return out;
  }

  Future<Map<String, int>> sumByMonthBetween({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final a = startInclusive.toUtc().toIso8601String();
    final b = endExclusive.toUtc().toIso8601String();
    final rows = await _db.rawQuery(
      '''
      SELECT substr(datetime(date, 'localtime'), 1, 7) AS month_key,
             COALESCE(SUM(amount_minor), 0) AS s
      FROM ${DbConstants.tableIncomes}
      WHERE date >= ? AND date < ?
      GROUP BY month_key
      ORDER BY month_key ASC
      ''',
      [a, b],
    );
    final out = <String, int>{};
    for (final r in rows) {
      final key = r['month_key'] as String?;
      if (key == null || key.isEmpty) continue;
      out[key] = (r['s'] as num?)?.toInt() ?? 0;
    }
    return out;
  }

  Future<void> insertOrReplace(IncomeModel model) async {
    await _db.insert(
      DbConstants.tableIncomes,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableIncomes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
