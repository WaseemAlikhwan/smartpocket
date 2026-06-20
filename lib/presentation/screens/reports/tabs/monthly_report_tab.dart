import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/reports/reports_providers.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/month_nav_bar.dart';
import '../../../widgets/reports/cash_flow_card.dart';
import '../../../widgets/reports/category_pie_chart.dart';
import '../../../widgets/reports/comparison_chip.dart';
import '../../../widgets/reports/days_bar_chart.dart';
import '../../../widgets/reports/insights_section.dart';
import '../../../widgets/reports/report_stat_card.dart';
import '../../../widgets/reports/trend_line_chart.dart';

class MonthlyReportTab extends ConsumerWidget {
  const MonthlyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        const MonthNavBar(),
        reportAsync.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
          data: (r) {
            final code = settings?.baseCurrencyCode;
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
                          icon: Icons.savings_outlined,
                          title: 'صافي الربح',
                          value: formatMinorUnits(r.netMinor, locale, currencyCode: code),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'عدد العمليات',
                          value: '${r.transactionsCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.today_outlined,
                          title: 'متوسط الصرف اليومي',
                          value: formatMinorUnits(
                            r.dailyAverageExpenseMinor,
                            locale,
                            currencyCode: code,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          icon: Icons.local_fire_department_outlined,
                          title: 'أعلى فئة صرف',
                          value: r.topCategory?.name ?? 'لا يوجد',
                          subtitle: r.topCategory == null
                              ? null
                              : formatMinorUnits(
                                  r.topCategory!.amountMinor,
                                  locale,
                                  currencyCode: code,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CashFlowCard(
                    incomeMinor: r.totalIncomeMinor,
                    expenseMinor: r.totalExpenseMinor,
                    netMinor: r.netMinor,
                    locale: locale,
                    currencyCode: code,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ComparisonChip(
                          label: 'هذا الشهر vs الماضي',
                          result: r.expenseComparisonVsPreviousMonth,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ComparisonChip(
                          label: 'هذا الأسبوع vs الماضي',
                          result: r.expenseComparisonVsPreviousWeek,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CategoryPieChart(
                    categories: r.categories,
                    locale: locale,
                    currencyCode: code,
                  ),
                  const SizedBox(height: 16),
                  DaysBarChart(
                    title: 'أيام الشهر',
                    points: r.dailyExpenseSeries,
                  ),
                  const SizedBox(height: 16),
                  TrendLineChart(
                    title: 'اتجاه المصاريف والدخل',
                    expenseSeries: r.dailyExpenseSeries,
                    incomeSeries: r.dailyIncomeSeries,
                  ),
                  const SizedBox(height: 16),
                  InsightsSection(insights: r.insights),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
