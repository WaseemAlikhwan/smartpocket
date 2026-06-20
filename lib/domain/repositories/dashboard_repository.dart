import '../entities/dashboard_snapshot.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> snapshotForMonth({
    required int year,
    required int month,
  });
}
