import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/reports/daily_report.dart';
import '../../../domain/entities/reports/monthly_report.dart';
import '../../../domain/entities/reports/report_insight.dart';
import '../../../domain/entities/reports/yearly_report.dart';
import '../repository_providers.dart';
import '../selected_month_provider.dart';
import 'selected_day_provider.dart';
import 'selected_year_provider.dart';

final dailyReportProvider = FutureProvider.autoDispose<DailyReport>((ref) async {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(reportsRepositoryProvider).dailyReport(day);
});

final monthlyReportProvider = FutureProvider.autoDispose<MonthlyReport>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(reportsRepositoryProvider).monthlyReport(
    year: ym.year,
    month: ym.month,
  );
});

final yearlyReportProvider = FutureProvider.autoDispose<YearlyReport>((ref) async {
  final year = ref.watch(selectedYearProvider);
  return ref.watch(reportsRepositoryProvider).yearlyReport(year: year);
});

final monthlyReportInsightsProvider = FutureProvider.autoDispose<List<ReportInsight>>((ref) async {
  final ym = ref.watch(selectedMonthProvider);
  return ref.watch(reportsRepositoryProvider).insightsForMonth(
    year: ym.year,
    month: ym.month,
  );
});
