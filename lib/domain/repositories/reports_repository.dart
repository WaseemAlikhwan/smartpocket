import '../entities/reports/daily_report.dart';
import '../entities/reports/monthly_report.dart';
import '../entities/reports/yearly_report.dart';
import '../entities/reports/report_insight.dart';

/// Single source of truth for analytical aggregates surfaced in the
/// reports screen. Implementations are expected to push grouping work
/// down into SQL rather than scanning rows in Dart.
abstract class ReportsRepository {
  /// Daily totals for the local calendar day [day], plus comparison to
  /// the previous local day.
  Future<DailyReport> dailyReport(DateTime day);

  /// Full monthly report including categories breakdown, daily series,
  /// week/month comparisons, and insights.
  Future<MonthlyReport> monthlyReport({required int year, required int month});

  /// Yearly report with 12 dense monthly summaries plus best/worst month.
  Future<YearlyReport> yearlyReport({required int year});

  /// Smart insights for the given month (also embedded in [monthlyReport]
  /// but exposed independently for screens that need them in isolation).
  Future<List<ReportInsight>> insightsForMonth({
    required int year,
    required int month,
  });
}
