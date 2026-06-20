import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/recurring_entry_entity.dart';
import '../providers/categories_list_provider.dart';
import '../providers/repository_providers.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';

class AddEditRecurringEntryScreen extends ConsumerStatefulWidget {
  const AddEditRecurringEntryScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<AddEditRecurringEntryScreen> createState() =>
      _AddEditRecurringEntryScreenState();
}

class _AddEditRecurringEntryScreenState extends ConsumerState<AddEditRecurringEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _payloadPersonCtrl = TextEditingController();
  final _payloadNoteCtrl = TextEditingController();
  int _day = 1;
  bool _active = true;
  RecurringEntryKind _kind = RecurringEntryKind.income;
  String? _categoryId;
  RecurringEntryEntity? _existing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final id = widget.entryId;
    if (id == null) return;
    final entry = await ref.read(recurringRepositoryProvider).getById(id);
    if (entry == null || !mounted) return;
    final payload = _decodePayload(entry.payloadJson);
    setState(() {
      _existing = entry;
      _titleCtrl.text = entry.title;
      _amountCtrl.text = (entry.amountMinor / 100).toStringAsFixed(2);
      _day = entry.dayOfMonth;
      _active = entry.isActive;
      _kind = entry.entryKind;
      _categoryId = payload['category_id']?.toString();
      _payloadPersonCtrl.text = payload['person_name']?.toString() ?? '';
      _payloadNoteCtrl.text = payload['note']?.toString() ?? '';
    });
  }

  Map<String, dynamic> _decodePayload(String raw) {
    try {
      final x = jsonDecode(raw);
      if (x is Map<String, dynamic>) return x;
    } catch (_) {}
    return {};
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseUserAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final settings = await ref.read(settingsRepositoryProvider).get();
    final payload = <String, dynamic>{'note': _payloadNoteCtrl.text.trim()};
    if (_categoryId != null) payload['category_id'] = _categoryId;
    if (_payloadPersonCtrl.text.trim().isNotEmpty) {
      payload['person_name'] = _payloadPersonCtrl.text.trim();
    }

    final now = DateTime.now().toUtc();
    await ref.read(recurringRepositoryProvider).upsert(
      RecurringEntryEntity(
        id: widget.entryId ?? const Uuid().v4(),
        entryKind: _kind,
        title: _titleCtrl.text.trim(),
        amountMinor: minorFromMajor(amount),
        currencyCode: settings?.baseCurrencyCode ?? 'SYP',
        dayOfMonth: _day,
        isActive: _active,
        payloadJson: jsonEncode(payload),
        lastConfirmedYm: _existing?.lastConfirmedYm ?? '',
        createdAt: _existing?.createdAt ?? now,
      ),
    );
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.entryId;
    if (id == null) return;
    await ref.read(recurringRepositoryProvider).delete(id);
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _payloadPersonCtrl.dispose();
    _payloadNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final isEdit = widget.entryId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل عنصر متكرر' : 'إضافة عنصر متكرر'),
        actions: [
          if (isEdit) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          TextButton(onPressed: _save, child: const Text('حفظ')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'العنوان'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecurringEntryKind>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'النوع'),
              items: const [
                DropdownMenuItem(value: RecurringEntryKind.income, child: Text('دخل')),
                DropdownMenuItem(value: RecurringEntryKind.expense, child: Text('مصروف')),
                DropdownMenuItem(value: RecurringEntryKind.debtOwedByMe, child: Text('دين عليك')),
                DropdownMenuItem(value: RecurringEntryKind.debtOwedToMe, child: Text('دين لك')),
              ],
              onChanged: (v) => setState(() => _kind = v ?? RecurringEntryKind.income),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) => parseUserAmount(v ?? '') == null ? 'قيمة غير صالحة' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _day,
              decoration: const InputDecoration(labelText: 'اليوم الشهري'),
              items: [
                for (var i = 1; i <= 28; i++)
                  DropdownMenuItem(value: i, child: Text(i.toString())),
              ],
              onChanged: (v) => setState(() => _day = v ?? 1),
            ),
            if (_kind == RecurringEntryKind.expense) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'فئة المصروف'),
                items: [
                  for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
            if (_kind == RecurringEntryKind.debtOwedByMe ||
                _kind == RecurringEntryKind.debtOwedToMe) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _payloadPersonCtrl,
                decoration: const InputDecoration(labelText: 'اسم الشخص'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _payloadNoteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              title: const Text('تفعيل'),
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
