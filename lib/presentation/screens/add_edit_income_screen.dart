import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/default_income_sources.dart';
import '../../domain/entities/income_entity.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_month_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';

class AddEditIncomeScreen extends ConsumerStatefulWidget {
  const AddEditIncomeScreen({super.key, this.incomeId});

  final String? incomeId;

  @override
  ConsumerState<AddEditIncomeScreen> createState() =>
      _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends ConsumerState<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String? _source;
  DateTime _date = DateTime.now();
  IncomeEntity? _existing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final id = widget.incomeId;
    if (id == null) return;
    final x = await ref.read(incomeRepositoryProvider).getById(id);
    if (x == null || !mounted) return;
    setState(() {
      _existing = x;
      _amountCtrl.text = (x.amountMinor / 100).toStringAsFixed(2);
      _source = x.source.isEmpty ? defaultIncomeSources.first : x.source;
      _date = x.date;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseUserAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final settings = await ref.read(settingsRepositoryProvider).get();
    final code = settings?.baseCurrencyCode ?? 'SYP';
    final now = DateTime.now().toUtc();
    final d = DateTime.utc(_date.year, _date.month, _date.day);

    await ref
        .read(incomeRepositoryProvider)
        .upsert(
          IncomeEntity(
            id: widget.incomeId ?? const Uuid().v4(),
            amountMinor: minorFromMajor(amount),
            currencyCode: code,
            date: d,
            source: _source ?? defaultIncomeSources.first,
            createdAt: _existing?.createdAt ?? now,
          ),
        );
    ref.read(selectedMonthProvider.notifier).state = (
      year: d.year,
      month: d.month,
    );
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.incomeId;
    if (id == null) return;
    await ref.read(incomeRepositoryProvider).delete(id);
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.incomeId != null;
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final sources = [...defaultIncomeSources];
    final selectedSource =
        (() {
          final value = _source;
          if (value == null || value.isEmpty) return sources.first;
          if (!sources.contains(value)) sources.add(value);
          return value;
        })();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل دخل' : 'إضافة دخل'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: _save, child: const Text('حفظ')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'المبلغ (${settings?.baseCurrencyCode ?? 'SYP'})',
              ),
              validator:
                  (v) =>
                      parseUserAmount(v ?? '') == null
                          ? 'قيمة غير صالحة'
                          : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSource,
              decoration: const InputDecoration(labelText: 'مصدر الدخل'),
              items:
                  sources
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التاريخ'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 3650),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}
