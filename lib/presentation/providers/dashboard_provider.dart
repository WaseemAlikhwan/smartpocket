import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_snapshot.dart';
import 'repository_providers.dart';
import 'selected_month_provider.dart';

final dashboardSnapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot>((ref) async {
      final ym = ref.watch(selectedMonthProvider);
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.snapshotForMonth(year: ym.year, month: ym.month);
    });
