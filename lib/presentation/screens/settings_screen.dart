import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/finance_currency.dart';
import '../utils/invalidate_finance.dart';
import '../widgets/reports/export_report_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(appSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96, top: 8),
        children: [
          ListTile(
            title: const Text('إعدادات مالية أساسية'),
            subtitle: Text(
              settings == null
                  ? 'غير مضبوطة بعد'
                  : 'عملة: ${settings.baseCurrencyCode} · رصيد ابتدائي: ${settings.openingBalanceMinor / 100}',
            ),
            trailing: Icon(
              Icons.account_balance_wallet_outlined,
              color: cs.primary,
            ),
            onTap: () => _openFinanceSettings(context, ref, settings),
          ),
          ListTile(
            title: const Text('أهداف التوفير'),
            subtitle: const Text('هدف بمبلغ وتاريخ — تقدير التوفير الشهري'),
            trailing: Icon(Icons.flag_outlined, color: cs.primary),
            onTap: () => context.push('/savings-goals'),
          ),
          ListTile(
            title: const Text('الدخل'),
            subtitle: const Text('إدارة عمليات الدخل الشهرية'),
            trailing: Icon(Icons.trending_up, color: cs.primary),
            onTap: () => context.push('/incomes'),
          ),
          ListTile(
            title: const Text('الديون'),
            subtitle: const Text('إدارة الديون عليك والديون لك'),
            trailing: Icon(Icons.receipt_long, color: cs.primary),
            onTap: () => context.push('/debts'),
          ),
          ListTile(
            title: const Text('العناصر المتكررة'),
            subtitle: const Text('دخل/مصروف/دين دوري مع تذكير شهري'),
            trailing: Icon(Icons.loop, color: cs.primary),
            onTap: () => context.push('/recurring'),
          ),
          const Divider(height: 28),
          const ListTile(
            title: Text('المظهر'),
            subtitle: Text('فاتح / داكن / النظام'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('فاتح'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('داكن'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('النظام'),
                  icon: Icon(Icons.phone_android_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) {
                final sel = s.first;
                ref.read(themeModeProvider.notifier).setMode(sel);
              },
            ),
          ),
          const Divider(height: 28),
          ListTile(
            title: const Text('تصدير التقارير (PDF / Excel)'),
            subtitle: const Text(
              'مصاريف أو دخل أو الكل حسب اليوم أو الشهر أو السنة.',
            ),
            trailing: Icon(Icons.ios_share_outlined, color: cs.primary),
            onTap: () async => showReportExportDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

Future<void> _openFinanceSettings(
  BuildContext context,
  WidgetRef ref,
  SettingsEntity? current,
) async {
  final opening = TextEditingController(
    text:
        current == null
            ? ''
            : (current.openingBalanceMinor / 100).toStringAsFixed(2),
  );
  final monthlyIncome = TextEditingController(
    text:
        current == null
            ? ''
            : (current.defaultMonthlyIncomeMinor / 100).toStringAsFixed(2),
  );
  var currency = currencyFromCode(current?.baseCurrencyCode ?? 'SYP');

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('الإعدادات المالية'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: opening,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الرصيد الحالي',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: monthlyIncome,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الدخل الشهري الافتراضي',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FinanceCurrency>(
                      value: currency,
                      decoration: const InputDecoration(
                        labelText: 'العملة الأساسية',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: FinanceCurrency.syp,
                          child: Text('SYP'),
                        ),
                        DropdownMenuItem(
                          value: FinanceCurrency.usd,
                          child: Text('USD'),
                        ),
                        DropdownMenuItem(
                          value: FinanceCurrency.eur,
                          child: Text('EUR'),
                        ),
                      ],
                      onChanged:
                          (v) => setState(
                            () => currency = v ?? FinanceCurrency.syp,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
  if (ok != true) return;
  final op = parseUserAmount(opening.text) ?? 0;
  final salary = parseUserAmount(monthlyIncome.text) ?? 0;
  final now = DateTime.now().toUtc();
  await ref
      .read(settingsRepositoryProvider)
      .upsert(
        SettingsEntity(
          id: current?.id ?? 'main',
          openingBalanceMinor: minorFromMajor(op),
          defaultMonthlyIncomeMinor: minorFromMajor(salary),
          baseCurrencyCode: currencyCode(currency),
          onboardingCompleted: true,
          budgetAlertPeriod:
              current?.budgetAlertPeriod ?? BudgetAlertPeriod.month,
          createdAt: current?.createdAt ?? now,
          updatedAt: now,
        ),
      );
  invalidateFinanceCaches(ref);
}
