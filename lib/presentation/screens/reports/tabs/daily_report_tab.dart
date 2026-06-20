import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/reports/reports_providers.dart';
import '../../../providers/reports/selected_day_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/reports/comparison_chip.dart';
import '../../../widgets/reports/report_stat_card.dart';

class DailyReportTab extends ConsumerWidget {
  const DailyReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final reportAsync = ref.watch(dailyReportProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('اليوم المحدد'),
            subtitle: Text(MaterialLocalizations.of(context).formatFullDate(selected)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selected,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                ref.read(selectedDayProvider.notifier).state = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        reportAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text('$e'),
          ),
          data: (r) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportStatCard(
                      icon: Icons.trending_up,
                      title: 'دخل اليوم',
                      value: formatMinorUnits(
                        r.totalIncomeMinor,
                        locale,
                        currencyCode: settings?.baseCurrencyCode,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ReportStatCard(
                      icon: Icons.trending_down,
                      title: 'مصروف اليوم',
                      value: formatMinorUnits(
                        r.totalExpenseMinor,
                        locale,
                        currencyCode: settings?.baseCurrencyCode,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ReportStatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'صافي اليوم',
                      value: formatMinorUnits(
                        r.netMinor,
                        locale,
                        currencyCode: settings?.baseCurrencyCode,
                      ),
                      subtitle: 'عدد العمليات: ${r.transactionsCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ComparisonChip(
                  label: 'مقارنة مع أمس',
                  result: r.expenseComparisonVsYesterday,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
