import '../entities/balance_snapshot.dart';
import '../entities/smart_insight.dart';

abstract class BalanceRepository {
  Future<BalanceSnapshot> snapshotForMonth({required int year, required int month});
  Future<List<SmartInsight>> insightsForMonth({required int year, required int month});
}
