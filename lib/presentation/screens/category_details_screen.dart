import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';
import '../providers/categories_list_provider.dart';
import '../providers/category_budget_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_month_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/budget_period_math.dart';
import '../utils/category_icon.dart';
import '../utils/invalidate_finance.dart';
import '../utils/money_format.dart';
import '../widgets/month_nav_bar.dart';

class CategoryDetailsScreen extends ConsumerStatefulWidget {
  const CategoryDetailsScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  ConsumerState<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends ConsumerState<CategoryDetailsScreen> {
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

  void _refreshMonthData(({int year, int month}) ym) {
    ref.invalidate(
      _categoryMonthExpensesProvider((
        categoryId: widget.categoryId,
        year: ym.year,
        month: ym.month,
      )),
    );
  }

  Future<void> _openAdd(({int year, int month}) ym) async {
    await context.push('/expense/add?categoryId=${widget.categoryId}');
    invalidateFinanceCaches(ref);
    _refreshMonthData(ym);
  }

  Future<void> _openEdit(String expenseId, ({int year, int month}) ym) async {
    await context.push('/expense/edit/$expenseId');
    invalidateFinanceCaches(ref);
    _refreshMonthData(ym);
  }

  Future<void> _deleteExpense(
    BuildContext context,
    String expenseId,
    ({int year, int month}) ym,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العملية؟'),
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
    await ref.read(expenseRepositoryProvider).delete(expenseId);
    invalidateFinanceCaches(ref);
    _refreshMonthData(ym);
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currencyCode = ref.watch(appSettingsProvider).valueOrNull?.baseCurrencyCode;
    final monthExpensesAsync = ref.watch(
      _categoryMonthExpensesProvider((
        categoryId: widget.categoryId,
        year: selectedMonth.year,
        month: selectedMonth.month,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفئة'),
        actions: [
          IconButton(
            tooltip: 'إضافة عملية',
            onPressed: () => _openAdd(selectedMonth),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) {
          CategoryEntity? category;
          for (final c in cats) {
            if (c.id == widget.categoryId) {
              category = c;
              break;
            }
          }
          if (category == null) {
            return const Center(child: Text('هذه الفئة غير متاحة.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeaderCard(
                category: category,
                categoryId: widget.categoryId,
                locale: locale,
                currencyCode: currencyCode,
                monthExpensesAsync: monthExpensesAsync,
              ),
              const SizedBox(height: 12),
              const MonthNavBar(),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'بحث داخل عمليات الفئة',
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
                              onPressed: () => _pickDay(context, selectedMonth),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _pickedDay == null
                                    ? 'اختيار يوم'
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatMediumDate(_pickedDay!),
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
              const SizedBox(height: 8),
              monthExpensesAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('$e'),
                  ),
                ),
                data: (rows) {
                  final q = _query.toLowerCase();
                  final filtered = rows.where((e) {
                    final noteMatch =
                        q.isEmpty || e.note.toLowerCase().contains(q);
                    final dayMatch =
                        _pickedDay == null ||
                        (e.date.year == _pickedDay!.year &&
                            e.date.month == _pickedDay!.month &&
                            e.date.day == _pickedDay!.day);
                    return noteMatch && dayMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('لا توجد نتائج مطابقة ضمن الشهر المحدد.'),
                      ),
                    );
                  }

                  final grouped = <DateTime, List<ExpenseEntity>>{};
                  for (final e in filtered) {
                    final day = DateTime(e.date.year, e.date.month, e.date.day);
                    grouped.putIfAbsent(day, () => <ExpenseEntity>[]).add(e);
                  }
                  final days = grouped.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return Card(
                    child: Column(
                      children: [
                        for (final day in days) ...[
                          ListTile(
                            title: Text(
                              MaterialLocalizations.of(context).formatMediumDate(day),
                            ),
                            trailing: Text(
                              formatMinorUnits(
                                grouped[day]!.fold<int>(
                                  0,
                                  (sum, e) => sum + e.amountMinor,
                                ),
                                locale,
                                currencyCode: currencyCode,
                              ),
                            ),
                          ),
                          ...grouped[day]!.map((e) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                e.note.isEmpty ? 'مصروف' : e.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                formatMinorUnits(
                                  e.amountMinor,
                                  locale,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              onTap: () => _openEdit(e.id, selectedMonth),
                              onLongPress: () =>
                                  _deleteExpense(context, e.id, selectedMonth),
                            );
                          }),
                          if (day != days.last) const Divider(height: 1),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.category,
    required this.categoryId,
    required this.locale,
    required this.currencyCode,
    required this.monthExpensesAsync,
  });

  final CategoryEntity category;
  final String categoryId;
  final String locale;
  final String? currencyCode;
  final AsyncValue<List<ExpenseEntity>> monthExpensesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(category.colorValue);
    final thisMonth = monthExpensesAsync.valueOrNull?.fold<int>(
          0,
          (sum, e) => sum + e.amountMinor,
        ) ??
        0;
    final count = monthExpensesAsync.valueOrNull?.length ?? 0;
    final budgetAsync = ref.watch(categoryBudgetForSelectedMonthProvider(categoryId));
    final ym = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final defaultPeriod = settings?.budgetAlertPeriod ?? BudgetAlertPeriod.month;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.35),
              child: Icon(resolveCategoryIcon(category.iconKey), size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _NumberTile(
                    label: 'هذا الشهر',
                    value: formatMinorUnits(
                      thisMonth,
                      locale,
                      currencyCode: currencyCode,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberTile(
                    label: 'عدد العمليات',
                    value: '$count',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            budgetAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (budget) => _CategoryBudgetEditor(
                categoryId: categoryId,
                year: ym.year,
                month: ym.month,
                budget: budget,
                spentThisMonthMinor: thisMonth,
                defaultAlertPeriod: defaultPeriod,
                locale: locale,
                currencyCode: currencyCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetEditor extends ConsumerStatefulWidget {
  const _CategoryBudgetEditor({
    required this.categoryId,
    required this.year,
    required this.month,
    required this.budget,
    required this.spentThisMonthMinor,
    required this.defaultAlertPeriod,
    required this.locale,
    required this.currencyCode,
  });

  final String categoryId;
  final int year;
  final int month;
  final BudgetEntity? budget;
  final int spentThisMonthMinor;
  final BudgetAlertPeriod defaultAlertPeriod;
  final String locale;
  final String? currencyCode;

  @override
  ConsumerState<_CategoryBudgetEditor> createState() => _CategoryBudgetEditorState();
}

class _CategoryBudgetEditorState extends ConsumerState<_CategoryBudgetEditor> {
  final _amountCtrl = TextEditingController();
  BudgetAlertPeriod _selectedPeriod = BudgetAlertPeriod.month;
  bool _overrun = false;

  @override
  void initState() {
    super.initState();
    _syncFromBudget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshOverrun();
    });
  }

  @override
  void didUpdateWidget(covariant _CategoryBudgetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final budgetChanged = oldWidget.budget?.id != widget.budget?.id ||
        oldWidget.budget?.limitAmountMinor != widget.budget?.limitAmountMinor ||
        oldWidget.budget?.alertPeriod != widget.budget?.alertPeriod ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month;
    if (budgetChanged) {
      _syncFromBudget();
    }
    if (oldWidget.spentThisMonthMinor != widget.spentThisMonthMinor ||
        oldWidget.defaultAlertPeriod != widget.defaultAlertPeriod ||
        budgetChanged) {
      _refreshOverrun();
    }
  }

  void _syncFromBudget() {
    final lim = widget.budget?.limitAmountMinor ?? 0;
    _amountCtrl.text =
        lim > 0 ? (lim / 100).toStringAsFixed(2) : '';
    _selectedPeriod = widget.budget?.alertPeriod ?? widget.defaultAlertPeriod;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshOverrun() async {
    final lim = widget.budget?.limitAmountMinor ?? 0;
    if (lim <= 0) {
      if (mounted) setState(() => _overrun = false);
      return;
    }
    final repo = ref.read(expenseRepositoryProvider);
    final over = await isCategoryBudgetOverrun(
      period: _selectedPeriod,
      year: widget.year,
      month: widget.month,
      categoryId: widget.categoryId,
      categoryLimitMinor: lim,
      spentThisMonthMinor: widget.spentThisMonthMinor,
      sumCategoryBetween: (cat, start, end) => repo.sumForCategoryBetween(
            categoryId: cat,
            startInclusive: start,
            endExclusive: end,
          ),
    );
    if (mounted) setState(() => _overrun = over);
  }

  Future<void> _save() async {
    final parsed = parseUserAmount(_amountCtrl.text);
    final repo = ref.read(budgetRepositoryProvider);
    final now = DateTime.now().toUtc();
    final ym = ref.read(selectedMonthProvider);

    if (parsed == null || parsed <= 0) {
      final existing = widget.budget;
      if (existing != null) {
        await repo.delete(existing.id);
      }
    } else {
      final minor = minorFromMajor(parsed);
      final existing = widget.budget;
      await repo.upsert(
        BudgetEntity(
          id: existing?.id ?? const Uuid().v4(),
          categoryId: widget.categoryId,
          year: ym.year,
          month: ym.month,
          limitAmountMinor: minor,
          alertPeriod: _selectedPeriod,
          createdAt: existing?.createdAt ?? now,
        ),
      );
    }
    invalidateFinanceCaches(ref);
    ref.invalidate(categoryBudgetForSelectedMonthProvider(widget.categoryId));
    await _refreshOverrun();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lim = widget.budget?.limitAmountMinor ?? 0;
    final limitLabel = _limitLabel(_selectedPeriod);
    final ratio =
        lim > 0 ? (widget.spentThisMonthMinor / lim).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ميزانية هذه الفئة',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: limitLabel,
                  hintText: 'اتركه فارغًا لإلغاء الميزانية',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('حفظ'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<BudgetAlertPeriod>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: BudgetAlertPeriod.month,
              label: Text('شهري'),
            ),
            ButtonSegment(
              value: BudgetAlertPeriod.week,
              label: Text('أسبوعي'),
            ),
            ButtonSegment(
              value: BudgetAlertPeriod.day,
              label: Text('يومي'),
            ),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (set) {
            setState(() => _selectedPeriod = set.first);
            _refreshOverrun();
          },
        ),
        if (lim > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: _overrun ? theme.colorScheme.error : theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'إجمالي الصرف في الشهر: ${formatMinorUnits(widget.spentThisMonthMinor, widget.locale, currencyCode: widget.currencyCode)} '
            'من ${formatMinorUnits(lim, widget.locale, currencyCode: widget.currencyCode)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'تنبيه التجاوز لهذه الفئة: ${_periodLabel(_selectedPeriod)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_overrun && lim > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'تنبيه: تجاوز حدّ الميزانية لهذه الفئة ضمن فترة ${_periodLabel(_selectedPeriod)}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  String _periodLabel(BudgetAlertPeriod p) {
    switch (p) {
      case BudgetAlertPeriod.month:
        return 'الشهر الكامل';
      case BudgetAlertPeriod.week:
        return 'الأسبوع الحالي (داخل الشهر)';
      case BudgetAlertPeriod.day:
        return 'اليوم الحالي';
    }
  }

  String _limitLabel(BudgetAlertPeriod p) {
    switch (p) {
      case BudgetAlertPeriod.month:
        return 'الحد الشهري';
      case BudgetAlertPeriod.week:
        return 'الحد الأسبوعي';
      case BudgetAlertPeriod.day:
        return 'الحد اليومي';
    }
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

typedef _CategoryMonthArgs = ({String categoryId, int year, int month});

final _categoryMonthExpensesProvider = FutureProvider.autoDispose
    .family<List<ExpenseEntity>, _CategoryMonthArgs>((ref, args) {
  return ref.watch(expenseRepositoryProvider).getForMonthByCategory(
        year: args.year,
        month: args.month,
        categoryId: args.categoryId,
      );
});
