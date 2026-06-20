import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/debt_entity.dart';
import '../providers/debt_payments_provider.dart';
import '../providers/repository_providers.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';
import '../utils/money_format.dart';

class DebtDetailsScreen extends ConsumerWidget {
  const DebtDetailsScreen({required this.debtId, super.key});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final debtAsync = FutureProvider.autoDispose((ref) {
      return ref.watch(debtRepositoryProvider).getById(debtId);
    });

    Future<void> addPartial(DebtEntity debt) async {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('إضافة دفعة'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'قيمة الدفعة'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
          ],
        ),
      );
      if (ok != true) return;
      final parsed = parseUserAmount(ctrl.text);
      if (parsed == null || parsed <= 0) return;
      await ref.read(debtRepositoryProvider).markPayment(
        id: debt.id,
        paidAmountMinor: minorFromMajor(parsed),
      );
      ref.invalidate(debtPaymentsProvider(debt.id));
      ref.invalidate(debtAsync);
      invalidateFinanceCaches(ref);
    }

    Future<void> markPaid(DebtEntity debt) async {
      await ref.read(debtRepositoryProvider).markPaid(debt.id);
      ref.invalidate(debtPaymentsProvider(debt.id));
      ref.invalidate(debtAsync);
      invalidateFinanceCaches(ref);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => context.go('/debts'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('تفاصيل الدين'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            onPressed: () => context.push('/debt/edit/$debtId'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final debtState = ref.watch(debtAsync);
          return debtState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (debt) {
              if (debt == null) return const Center(child: Text('لم يتم العثور على الدين.'));
              final payments = ref.watch(debtPaymentsProvider(debt.id));
              final isPaid = debt.status == DebtStatus.paid;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text('النوع: ${debt.type == DebtType.owedByMe ? 'دين عليك' : 'دين لك'}'),
                          Text(
                            'الإجمالي: ${formatMinorUnits(debt.amountMinor, locale, currencyCode: debt.currencyCode)}',
                          ),
                          Text(
                            'المدفوع: ${formatMinorUnits(debt.paidAmountMinor, locale, currencyCode: debt.currencyCode)}',
                          ),
                          Text(
                            'المتبقي: ${formatMinorUnits(debt.remainingAmountMinor, locale, currencyCode: debt.currencyCode)}',
                          ),
                          Text(
                            'الاستحقاق: ${MaterialLocalizations.of(context).formatMediumDate(debt.dueDate)}',
                          ),
                          if (debt.lastPaymentAt != null)
                            Text(
                              'آخر دفعة: ${MaterialLocalizations.of(context).formatMediumDate(debt.lastPaymentAt!)}',
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (!isPaid)
                                FilledButton.tonal(
                                  onPressed: () => addPartial(debt),
                                  child: const Text('دفعة جزئية'),
                                ),
                              const SizedBox(width: 8),
                              if (!isPaid)
                                FilledButton(
                                  onPressed: () => markPaid(debt),
                                  child: const Text('تم الدفع بالكامل'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'سجل الدفعات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  payments.when(
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
                      if (rows.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لا توجد دفعات مسجلة بعد.'),
                          ),
                        );
                      }
                      return Card(
                        child: Column(
                          children: rows.map((p) {
                            return ListTile(
                              title: Text(
                                formatMinorUnits(
                                  p.amountMinor,
                                  locale,
                                  currencyCode: debt.currencyCode,
                                ),
                              ),
                              subtitle: Text(
                                MaterialLocalizations.of(context).formatFullDate(p.paidAt),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
