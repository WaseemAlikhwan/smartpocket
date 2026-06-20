import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../models/settings_model.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._db);

  final Database _db;

  Future<SettingsModel?> get() async {
    final rows = await _db.query(
      DbConstants.tableSettings,
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SettingsModel.fromRow(rows.single);
  }

  Future<void> upsert(SettingsModel model) async {
    await _db.insert(
      DbConstants.tableSettings,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
