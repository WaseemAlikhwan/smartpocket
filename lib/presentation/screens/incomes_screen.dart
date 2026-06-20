import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/income_entity.dart';
import '../providers/income_month_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_month_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/invalidate_finance.dart';
import '../utils/money_format.dart';
import '../widgets/finance_top_tabs.dart';
import '../widgets/month_nav_bar.dart';

class IncomesScreen extends ConsumerStatefulWidget {
  const IncomesScreen({super.key});

  @override
  ConsumerState<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends ConsumerState<IncomesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DateTime? _pickedDay;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay(BuildContext context, ({int year, int month}) ym) async {
    final now = DateTime.now();
    final initial = _pickedDay ?? DateTime(ym.year, ym.month, now.day);
    final lastDay = DateTime(ym.year, ym.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDay) ? lastDay : initial,
      firstDate: DateTime(ym.year, ym.month, 1),
      lastDate: lastDay,
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() => _pickedDay = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _deleteIncome(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف عملية الدخل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(incomeRepositoryProvider).delete(id);
    invalidateFinanceCaches(ref);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final incomes = ref.watch(incomesForSelectedMonthProvider);
    final ym = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final code = settings?.baseCurrencyCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدخل الشهري'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const FinanceTopTabs(activeTab: FinanceTopTab.incomes),
          const MonthNavBar(),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث داخل الدخل',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDay(context, ym),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _pickedDay == null
                                ? 'اختيار يوم'
                                : MaterialLocalizations.of(context).formatMediumDate(
                                    _pickedDay!,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _pickedDay = null;
                          _query = '';
                          _searchCtrl.clear();
                        }),
                        child: const Text('مسح الفرز'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          incomes.when(
            data: (list) {
              final q = _query.toLowerCase();
              final filtered = list.where((e) {
                final sourceMatch = q.isEmpty || e.source.toLowerCase().contains(q);
                final amountMatch =
                    q.isEmpty || (e.amountMinor / 100).toStringAsFixed(2).contains(q);
                final dayMatch = _pickedDay == null
                    ? true
                    : (e.date.year == _pickedDay!.year &&
                        e.date.month == _pickedDay!.month &&
                        e.date.day == _pickedDay!.day);
                return (sourceMatch || amountMatch) && dayMatch;
              }).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد نتائج دخل مطابقة ضمن الشهر المحدد'),
                );
              }

              final grouped = <DateTime, List<IncomeEntity>>{};
              for (final e in filtered) {
                final day = DateTime(e.date.year, e.date.month, e.date.day);
                grouped.putIfAbsent(day, () => <IncomeEntity>[]).add(e);
              }
              final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final day in days) ...[
                      ListTile(
                        title: Text(MaterialLocalizations.of(context).formatMediumDate(day)),
                        trailing: Text(
                          formatMinorUnits(
                            grouped[day]!.fold<int>(0, (sum, e) => sum + e.amountMinor),
                            locale,
                            currencyCode: code,
                          ),
                        ),
                      ),
                      ...grouped[day]!.map((e) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.trending_up),
                          title: Text(
                            formatMinorUnits(
                              e.amountMinor,
                              locale,
                              currencyCode: e.currencyCode,
                            ),
                          ),
                          subtitle: Text(e.source),
                          trailing: Text(
                            e.currencyCode == 'SYP' && code != null ? code : e.currencyCode,
                          ),
                          onTap: () => context.push('/income/edit/${e.id}'),
                          onLongPress: () => _deleteIncome(e.id),
                        );
                      }),
                      if (day != days.last) const Divider(height: 1),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/income/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
