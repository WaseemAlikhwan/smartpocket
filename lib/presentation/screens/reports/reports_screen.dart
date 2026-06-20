import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/report_export_service.dart';
import '../../providers/reports/selected_day_provider.dart';
import '../../providers/reports/selected_year_provider.dart';
import '../../providers/selected_month_provider.dart';
import '../../widgets/reports/export_report_dialog.dart';
import 'tabs/daily_report_tab.dart';
import 'tabs/monthly_report_tab.dart';
import 'tabs/yearly_report_tab.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير التحليلية'),
          actions: [
            Builder(
              builder: (ctx) {
                final tabIndex = DefaultTabController.of(ctx).index;
                final periodType = switch (tabIndex) {
                  0 => ExportPeriodType.day,
                  1 => ExportPeriodType.month,
                  _ => ExportPeriodType.year,
                };
                final referenceDate = switch (tabIndex) {
                  0 => selectedDay,
                  1 => DateTime(selectedMonth.year, selectedMonth.month, 1),
                  _ => DateTime(selectedYear, 1, 1),
                };
                return IconButton(
                  tooltip: 'تصدير',
                  icon: const Icon(Icons.ios_share_outlined),
                  onPressed:
                      () => showReportExportDialog(
                        context,
                        ref,
                        initialPeriodType: periodType,
                        initialReferenceDate: referenceDate,
                      ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'يومي'), Tab(text: 'شهري'), Tab(text: 'سنوي')],
          ),
        ),
        body: const TabBarView(
          children: [DailyReportTab(), MonthlyReportTab(), YearlyReportTab()],
        ),
      ),
    );
  }
}
