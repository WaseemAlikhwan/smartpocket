import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/settings_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';
import '../providers/repository_providers.dart';
import '../utils/amount_parser.dart';
import '../utils/finance_currency.dart';
import '../utils/invalidate_finance.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _openingCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  FinanceCurrency _currency = FinanceCurrency.syp;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final opening = minorFromMajor(parseUserAmount(_openingCtrl.text) ?? 0);
    final salary = minorFromMajor(parseUserAmount(_salaryCtrl.text) ?? 0);
    final now = DateTime.now().toUtc();

    await ref.read(settingsRepositoryProvider).upsert(
      SettingsEntity(
        id: 'main',
        openingBalanceMinor: opening,
        defaultMonthlyIncomeMinor: salary,
        baseCurrencyCode: currencyCode(_currency),
        onboardingCompleted: true,
        budgetAlertPeriod: BudgetAlertPeriod.month,
        createdAt: now,
        updatedAt: now,
      ),
    );
    invalidateFinanceCaches(ref);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _openingCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعداد الأولي')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('أدخل بياناتك المالية الأساسية لمرة واحدة'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الحالي'),
              validator: (v) =>
                  parseUserAmount(v ?? '') == null ? 'قيمة غير صالحة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salaryCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الدخل الشهري (الراتب)'),
              validator: (v) =>
                  parseUserAmount(v ?? '') == null ? 'قيمة غير صالحة' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FinanceCurrency>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'العملة الأساسية'),
              items: const [
                DropdownMenuItem(value: FinanceCurrency.syp, child: Text('ليرة سورية (SYP)')),
                DropdownMenuItem(value: FinanceCurrency.usd, child: Text('دولار (USD)')),
                DropdownMenuItem(value: FinanceCurrency.eur, child: Text('يورو (EUR)')),
              ],
              onChanged: (v) => setState(() => _currency = v ?? FinanceCurrency.syp),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('بدء الاستخدام'),
            ),
          ],
        ),
      ),
    );
  }
}
