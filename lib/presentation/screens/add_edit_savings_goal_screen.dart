import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/savings_goal_entity.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/savings_goals_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/money_format.dart';
import '../utils/savings_goal_math.dart';

class AddEditSavingsGoalScreen extends ConsumerStatefulWidget {
  const AddEditSavingsGoalScreen({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<AddEditSavingsGoalScreen> createState() =>
      _AddEditSavingsGoalScreenState();
}

class _AddEditSavingsGoalScreenState
    extends ConsumerState<AddEditSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  SavingsGoalEntity? _existing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final id = widget.goalId;
    if (id == null) return;
    final g = await ref.read(savingsGoalRepositoryProvider).getById(id);
    if (g == null || !mounted) return;
    setState(() {
      _existing = g;
      _titleCtrl.text = g.title;
      _targetCtrl.text = (g.targetAmountMinor / 100).toStringAsFixed(2);
      _startDate = g.startDate;
      _targetDate = g.targetDate;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final min = _startDate.isAfter(now) ? _startDate : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isBefore(min) ? min : _targetDate,
      firstDate: min,
      lastDate: DateTime(now.year + 20),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = parseUserAmount(_targetCtrl.text);
    if (target == null || target <= 0) return;
    final settings = await ref.read(settingsRepositoryProvider).get();
    final code = settings?.baseCurrencyCode ?? 'SYP';
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime.utc(_targetDate.year, _targetDate.month, _targetDate.day);
    final targetMinor = minorFromMajor(target);
    final existingSaved = _existing?.savedAmountMinor ?? 0;
    final savedMinor = existingSaved.clamp(0, targetMinor);
    final status = savedMinor >= targetMinor
        ? SavingsGoalStatus.completed
        : SavingsGoalStatus.active;

    await ref.read(savingsGoalRepositoryProvider).upsert(
          SavingsGoalEntity(
            id: widget.goalId ?? const Uuid().v4(),
            title: _titleCtrl.text.trim().isEmpty ? 'هدف' : _titleCtrl.text.trim(),
            targetAmountMinor: targetMinor,
            savedAmountMinor: savedMinor,
            startDate: start,
            targetDate: end,
            status: status,
            currencyCode: code,
            createdAt: _existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    ref.invalidate(savingsGoalsProvider);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    final id = widget.goalId;
    if (id == null) return;
    await ref.read(savingsGoalRepositoryProvider).delete(id);
    ref.invalidate(savingsGoalsProvider);
    if (!mounted) return;
    context.pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goalId != null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final baseCode = settings?.baseCurrencyCode;

    final targetMinor = (parseUserAmount(_targetCtrl.text) != null)
        ? minorFromMajor(parseUserAmount(_targetCtrl.text)!)
        : 0;
    final savedMinor = _existing?.savedAmountMinor ?? 0;
    final suggested = monthlySavingsMinor(
      targetAmountMinor: targetMinor,
      savedAmountMinor: savedMinor.clamp(0, targetMinor),
      targetDate: _targetDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل هدف التوفير' : 'هدف توفير جديد'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'حذف',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف الهدف؟'),
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
                if (ok == true) await _delete();
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'الوصف (مثل: لابتوب)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ المستهدف',
              ),
              validator: (v) {
                final p = parseUserAmount(v ?? '');
                if (p == null || p <= 0) return 'أدخل مبلغًا صالحًا';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('تاريخ بدء الهدف'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatFullDate(_startDate),
              ),
              trailing: const Icon(Icons.event_available_outlined),
              onTap: _pickStartDate,
            ),
            ListTile(
              title: const Text('تاريخ تحقيق الهدف'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatFullDate(_targetDate),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickTargetDate,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقدير التوفير الشهري',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      targetMinor > 0
                          ? 'حوالي ${formatMinorUnits(suggested, locale, currencyCode: baseCode)} شهريًا حتى الموعد (تقريبًا بالتساوي).'
                          : 'أدخل المبلغ المستهدف لعرض التقدير.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_existing != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'المدّخر الحالي: ${formatMinorUnits(savedMinor, locale, currencyCode: baseCode)} (يُحدّث من زر إضافة دفعة).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
