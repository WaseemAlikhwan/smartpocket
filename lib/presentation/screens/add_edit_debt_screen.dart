import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/debt_entity.dart';
import '../providers/repository_providers.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';

class AddEditDebtScreen extends ConsumerStatefulWidget {
  const AddEditDebtScreen({super.key, this.debtId});

  final String? debtId;

  @override
  ConsumerState<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends ConsumerState<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DebtType _type = DebtType.owedByMe;
  DateTime _dueDate = DateTime.now();
  String? _contactId;
  DebtEntity? _existing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final id = widget.debtId;
    if (id == null) return;
    final d = await ref.read(debtRepositoryProvider).getById(id);
    if (d == null || !mounted) return;
    setState(() {
      _existing = d;
      _amountCtrl.text = (d.amountMinor / 100).toStringAsFixed(2);
      _nameCtrl.text = d.personName;
      _contactId = d.contactId;
      _noteCtrl.text = d.note;
      _type = d.type;
      _dueDate = d.dueDate;
    });
  }

  Future<void> _pickContact() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب منح إذن جهات الاتصال أولاً')));
      return;
    }
    final picked = await FlutterContacts.openExternalPick();
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = picked.displayName;
      _contactId = picked.id;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseUserAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final totalMinor = minorFromMajor(amount);
    final paidMinor = (_existing?.paidAmountMinor ?? 0).clamp(0, totalMinor);
    final remainingMinor = totalMinor - paidMinor;
    final settings = await ref.read(settingsRepositoryProvider).get();
    final now = DateTime.now().toUtc();

    await ref.read(debtRepositoryProvider).upsert(
      DebtEntity(
        id: widget.debtId ?? const Uuid().v4(),
        amountMinor: totalMinor,
        paidAmountMinor: paidMinor,
        remainingAmountMinor: remainingMinor,
        currencyCode: settings?.baseCurrencyCode ?? 'SYP',
        personName: _nameCtrl.text.trim(),
        contactId: _contactId,
        dueDate: DateTime.utc(_dueDate.year, _dueDate.month, _dueDate.day),
        type: _type,
        status: remainingMinor <= 0
            ? DebtStatus.paid
            : DebtStatus.pending,
        lastPaymentAt: _existing?.lastPaymentAt,
        reminderLastSentAt: _existing?.reminderLastSentAt,
        note: _noteCtrl.text.trim(),
        createdAt: _existing?.createdAt ?? now,
      ),
    );
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.debtId;
    if (id == null) return;
    await ref.read(debtRepositoryProvider).delete(id);
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.pop();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debtId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => context.go('/debts'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(isEdit ? 'تعديل دين' : 'إضافة دين'),
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
            DropdownButtonFormField<DebtType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'نوع الدين'),
              items: const [
                DropdownMenuItem(value: DebtType.owedByMe, child: Text('دين عليك')),
                DropdownMenuItem(value: DebtType.owedToMe, child: Text('دين لك')),
              ],
              onChanged: (v) => setState(() => _type = v ?? DebtType.owedByMe),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) => parseUserAmount(v ?? '') == null ? 'قيمة غير صالحة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم الشخص'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('معرف جهة الاتصال (اختياري)'),
              subtitle: Text(
                _contactId == null
                    ? 'اختيار من جهات اتصال الهاتف'
                    : 'تم ربط جهة اتصال',
              ),
              trailing: const Icon(Icons.contacts),
              onTap: _pickContact,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تاريخ الاستحقاق'),
              subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(_dueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
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
