import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._db);

  final Database _db;

  Future<List<CategoryModel>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableCategories,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(CategoryModel.fromRow).toList();
  }

  Future<void> insertOrReplace(CategoryModel model) async {
    await _db.insert(
      DbConstants.tableCategories,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    await _db.delete(DbConstants.tableCategories);
  }

  Future<void> insertAll(List<CategoryModel> list) async {
    final batch = _db.batch();
    for (final m in list) {
      batch.insert(
        DbConstants.tableCategories,
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
