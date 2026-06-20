import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/expense_entity.dart';
import '../providers/categories_list_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_month_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';

/// Add expense ([expenseId] null) or edit existing.
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({
    super.key,
    this.expenseId,
    this.initialCategoryId,
  });

  final String? expenseId;
  final String? initialCategoryId;

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _loading = true;
  ExpenseEntity? _existing;

  bool get _isEdit => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    ExpenseEntity? existing;
    if (widget.expenseId != null) {
      existing = await ref.read(expenseRepositoryProvider).getById(
        widget.expenseId!,
      );
    }
    if (!mounted) return;
    final requestedCategory = widget.initialCategoryId;
    final hasRequestedCategory =
        requestedCategory != null && cats.any((c) => c.id == requestedCategory);
    final cid =
        existing?.categoryId ??
        (hasRequestedCategory
            ? requestedCategory
            : (cats.isNotEmpty ? cats.first.id : null));
    final dt = existing?.date ?? DateTime.now();
    final date = DateTime(dt.year, dt.month, dt.day);
    setState(() {
      _existing = existing;
      _loading = false;
      _categoryId = cid;
      _date = date;
      if (existing != null) {
        _amountCtrl.text = (existing.amountMinor / 100.0).toStringAsFixed(2);
        _noteCtrl.text = existing.note;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amt = parseUserAmount(_amountCtrl.text);
    if (amt == null || amt <= 0) return;

    final cats = await ref.read(categoryRepositoryProvider).getAll();
    var cid =
        cats.any((c) => c.id == _categoryId) ? _categoryId! : cats.firstOrNull?.id;

    if (cid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أنشئ فئة قبل حفظ المصروف')),
      );
      return;
    }

    final repo = ref.read(expenseRepositoryProvider);
    final settings = await ref.read(settingsRepositoryProvider).get();
    final id = widget.expenseId ?? const Uuid().v4();
    final utcDate = DateTime.utc(_date.year, _date.month, _date.day);
    final nowUtc = DateTime.now().toUtc();

    await repo.upsert(
      ExpenseEntity(
        id: id,
        amountMinor: minorFromMajor(amt),
        categoryId: cid,
        currencyCode: settings?.baseCurrencyCode ?? _existing?.currencyCode ?? 'SYP',
        note: _noteCtrl.text.trim(),
        date: utcDate,
        createdAt: _existing?.createdAt ?? nowUtc,
      ),
    );

    invalidateFinanceCaches(ref);

    ref.read(selectedMonthProvider.notifier).state = (
      year: utcDate.year,
      month: utcDate.month,
    );

    if (!mounted) return;
    context.pop();
  }

  Future<void> _confirmDelete() async {
    final id = widget.expenseId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف المصروف؟'),
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
    await ref.read(expenseRepositoryProvider).delete(id);
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catsAsync = ref.watch(categoriesProvider);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مصروف' : 'إضافة مصروف'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'حذف',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _confirmDelete,
            ),
          TextButton(onPressed: _save, child: Text(_isEdit ? 'حفظ' : 'تم')),
        ],
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('أنشئ فئة أولاً من تبويب «الفئات».'),
              ),
            );
          }

          final selectedCatId =
              (_categoryId != null && cats.any((c) => c.id == _categoryId))
                  ? _categoryId!
                  : cats.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (v) {
                    final p = parseUserAmount(v ?? '');
                    if (p == null || p <= 0) {
                      return 'أدخل مبلغًا صحيحًا أكبر من صفر';
                    }
                    return null;
                  },
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items:
                      cats
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() => _categoryId = v);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('اليوم المُسجل'),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatMediumDate(_date),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(_isEdit ? 'تحديث' : 'حفظ المصروف'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _FirstCat<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
