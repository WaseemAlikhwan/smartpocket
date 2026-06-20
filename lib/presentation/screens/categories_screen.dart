import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/categories_list_provider.dart';
import '../providers/expense_month_provider.dart';
import '../providers/selected_month_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/category_icon.dart';
import '../utils/money_format.dart';
import '../widgets/finance_top_tabs.dart';
import '../widgets/month_nav_bar.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DateTime? _pickedDay;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime _effectiveDay(({int year, int month}) ym) {
    final now = DateTime.now();
    final fallbackDay = ym.year == now.year && ym.month == now.month ? now.day : 1;
    final selected = _pickedDay ?? DateTime(ym.year, ym.month, fallbackDay);
    final lastDay = DateTime(ym.year, ym.month + 1, 0).day;
    final day = selected.day.clamp(1, lastDay);
    return DateTime(ym.year, ym.month, day);
  }

  Future<void> _pickDay(BuildContext context, ({int year, int month}) ym) async {
    final initial = _effectiveDay(ym);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(ym.year, ym.month, 1),
      lastDate: DateTime(ym.year, ym.month + 1, 0),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() => _pickedDay = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(expensesForSelectedMonthProvider);
    final ym = ref.watch(selectedMonthProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final baseCurrency = ref.watch(appSettingsProvider).valueOrNull?.baseCurrencyCode;
    final selectedDay = _effectiveDay(ym);

    return Scaffold(
      appBar: AppBar(title: const Text('المصروف')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'إضافة مصروف',
        onPressed: () => context.push('/expense/add'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const FinanceTopTabs(activeTab: FinanceTopTab.expenses),
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
                      hintText: 'بحث داخل مصاريف اليوم',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح',
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
                            MaterialLocalizations.of(context).formatMediumDate(selectedDay),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _pickedDay = null;
                          _searchCtrl.clear();
                          _query = '';
                        }),
                        child: const Text('مسح الفرز'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          expensesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$e'),
            ),
            data: (list) {
              final q = _query.toLowerCase();
              final cats = catsAsync.valueOrNull ?? const <CategoryEntity>[];
              final nameById = {for (final c in cats) c.id: c.name};
              final iconById = {for (final c in cats) c.id: c.iconKey};

              final filtered = list.where((e) {
                final sameDay = e.date.year == selectedDay.year &&
                    e.date.month == selectedDay.month &&
                    e.date.day == selectedDay.day;
                if (!sameDay) return false;
                if (q.isEmpty) return true;
                final noteMatch = e.note.toLowerCase().contains(q);
                final catMatch = (nameById[e.categoryId] ?? '').toLowerCase().contains(q);
                return noteMatch || catMatch;
              }).toList();

              final totalMinor = filtered.fold<int>(0, (sum, e) => sum + e.amountMinor);

              return Card(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: const Text('إجمالي اليوم'),
                        subtitle: Text(
                          MaterialLocalizations.of(context).formatFullDate(selectedDay),
                        ),
                        trailing: Text(
                          formatMinorUnits(
                            totalMinor,
                            locale,
                            currencyCode: baseCurrency,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا توجد مصاريف مطابقة في هذا اليوم.'),
                        )
                      else
                        ...filtered.map((e) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                resolveCategoryIcon(iconById[e.categoryId] ?? 'category'),
                                size: 18,
                              ),
                            ),
                            title: Text(nameById[e.categoryId] ?? 'فئة'),
                            subtitle: Text(e.note.isEmpty ? 'مصروف' : e.note),
                            trailing: Text(
                              formatMinorUnits(
                                e.amountMinor,
                                locale,
                                currencyCode: e.currencyCode,
                              ),
                            ),
                            onTap: () => context.push('/expense/edit/${e.id}'),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
          catsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$e'),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'لا توجد فئات بعد.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.folder_open_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    'الفئات',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    '${list.length} فئة — عرض القائمة وتفاصيل كل فئة',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/categories/browse'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
