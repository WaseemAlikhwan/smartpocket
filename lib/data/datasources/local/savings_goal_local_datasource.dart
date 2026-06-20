import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/savings_goal_entity.dart';
import '../../models/saving_goal_contribution_model.dart';
import '../../models/savings_goal_model.dart';

class SavingsGoalLocalDataSource {
  SavingsGoalLocalDataSource(this._db);

  final Database _db;

  SavingsGoalModel _applyStatus(SavingsGoalModel model) {
    final cappedSaved = model.savedAmountMinor.clamp(0, model.targetAmountMinor);
    final status = cappedSaved >= model.targetAmountMinor
        ? SavingsGoalStatus.completed
        : SavingsGoalStatus.active;
    return SavingsGoalModel(
      id: model.id,
      title: model.title,
      targetAmountMinor: model.targetAmountMinor,
      savedAmountMinor: cappedSaved,
      startDate: model.startDate,
      targetDate: model.targetDate,
      status: status,
      currencyCode: model.currencyCode,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  Future<List<SavingsGoalModel>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableSavingsGoals,
      orderBy: 'target_date ASC, created_at ASC',
    );
    return rows.map(SavingsGoalModel.fromRow).toList();
  }

  Future<SavingsGoalModel?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableSavingsGoals,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SavingsGoalModel.fromRow(rows.single);
  }

  Future<void> insertOrReplace(SavingsGoalModel model) async {
    final normalized = _applyStatus(model);
    final updated = await _db.update(
      DbConstants.tableSavingsGoals,
      normalized.toMap(),
      where: 'id = ?',
      whereArgs: [normalized.id],
    );
    if (updated == 0) {
      await _db.insert(
        DbConstants.tableSavingsGoals,
        normalized.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableSavingsGoals,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addContribution({
    required String id,
    required int amountMinor,
    required DateTime paidAt,
  }) async {
    if (amountMinor <= 0) return;
    final current = await getById(id);
    if (current == null) return;
    final now = paidAt.toUtc();
    final nextSaved = current.savedAmountMinor + amountMinor;
    final updated = _applyStatus(
      SavingsGoalModel(
        id: current.id,
        title: current.title,
        targetAmountMinor: current.targetAmountMinor,
        savedAmountMinor: nextSaved,
        startDate: current.startDate,
        targetDate: current.targetDate,
        status: current.status,
        currencyCode: current.currencyCode,
        createdAt: current.createdAt,
        updatedAt: now,
      ),
    );
    await _db.update(
      DbConstants.tableSavingsGoals,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SavingGoalContributionModel>> listContributions(String goalId) async {
    final rows = await _db.query(
      DbConstants.tableSavingsGoalContributions,
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'created_at DESC',
    );
    return rows.map(SavingGoalContributionModel.fromRow).toList();
  }

  Future<SavingGoalContributionModel?> getContributionById(String id) async {
    final rows = await _db.query(
      DbConstants.tableSavingsGoalContributions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SavingGoalContributionModel.fromRow(rows.single);
  }

  Future<void> insertContribution(SavingGoalContributionModel model) async {
    await _db.insert(
      DbConstants.tableSavingsGoalContributions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateContribution(SavingGoalContributionModel model) async {
    await _db.update(
      DbConstants.tableSavingsGoalContributions,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> deleteContribution(String id) async {
    await _db.delete(
      DbConstants.tableSavingsGoalContributions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
