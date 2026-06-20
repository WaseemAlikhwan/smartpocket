import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/reports/reports_providers.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/reports/months_bar_chart.dart';
import '../../../widgets/reports/report_stat_card.dart';
import '../../../widgets/reports/trend_line_chart.dart';
import '../../../widgets/reports/year_nav_bar.dart';

class YearlyReportTab extends ConsumerWidget {
  const YearlyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(yearlyReportProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        const YearNavBar(),
        reportAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
          data: (r) {
            final code = settings?.baseCurrencyCode;
            final best = r.bestMonth == null ? 'لا يوجد' : '${r.bestMonth!.month}/${r.bestMonth!.year}';
            final worst = r.worstMonth == null ? 'لا يوجد' : '${r.worstMonth!.month}/${r.worstMonth!.year}';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.trending_up,
                          title: 'مجموع الدخل',
                          value: formatMinorUnits(r.totalIncomeMinor, locale, currencyCode: code),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.trending_down,
                          title: 'مجموع المصاريف',
                          value: formatMinorUnits(r.totalExpenseMinor, locale, currencyCode: code),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.thumb_up_alt_outlined,
                          title: 'أفضل شهر (أقل صرف)',
                          value: best,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.warning_amber_outlined,
                          title: 'أسوأ شهر (أعلى صرف)',
                          value: worst,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MonthsBarChart(
                    title: 'المصاريف عبر أشهر السنة',
                    points: r.monthlyExpenseSeries,
                  ),
                  const SizedBox(height: 16),
                  TrendLineChart(
                    title: 'الدخل مقابل المصاريف (سنوي)',
                    expenseSeries: r.monthlyExpenseSeries,
                    incomeSeries: r.monthlyIncomeSeries,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
