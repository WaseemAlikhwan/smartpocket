import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/saving_goal_contribution_entity.dart';
import '../providers/repository_providers.dart';
import '../providers/selected_month_provider.dart';
import '../providers/savings_goals_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';
import '../utils/money_format.dart';
import '../utils/savings_goal_math.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingsGoalsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('أهداف التوفير'),
        actions: [
          IconButton(
            tooltip: 'إضافة',
            onPressed: () => context.push('/savings-goal/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'لا توجد أهداف. اضغط + لإضافة هدف (مثل لابتوب) ويُقترح مبلغ التوفير شهريًا.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = list[i];
              return _GoalCard(goal: g, locale: locale);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'هدف جديد',
        onPressed: () => context.push('/savings-goal/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.locale});

  final SavingsGoalEntity goal;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remaining = remainingAmountMinor(
      targetAmountMinor: goal.targetAmountMinor,
      savedAmountMinor: goal.savedAmountMinor,
    );
    final monthly = monthlySavingsMinor(
      targetAmountMinor: goal.targetAmountMinor,
      savedAmountMinor: goal.savedAmountMinor,
      targetDate: goal.targetDate,
    );
    final progress = progressRatio(
      targetAmountMinor: goal.targetAmountMinor,
      savedAmountMinor: goal.savedAmountMinor,
    );
    final nearDeadline = isNearDeadline(goal.targetDate);
    final percentage = (progress * 100).round();
    final completed = goal.status == SavingsGoalStatus.completed;
    final suggestion = completed
        ? 'ممتاز! اكتمل الهدف بنجاح.'
        : 'يمكنك الوصول أسرع إذا زدت الادخار الشهري عن ${formatMinorUnits(monthly, locale, currencyCode: goal.currencyCode)}.';

    return Card(
      child: InkWell(
        onTap: () => context.push('/savings-goal/edit/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    completed ? 'completed' : 'active',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الهدف: ${formatMinorUnits(goal.targetAmountMinor, locale, currencyCode: goal.currencyCode)} · '
                'المدّخر: ${formatMinorUnits(goal.savedAmountMinor, locale, currencyCode: goal.currencyCode)}',
                style: theme.textTheme.bodyMedium,
              ),
              if (remaining > 0)
                Text(
                  'المتبقي: ${formatMinorUnits(remaining, locale, currencyCode: goal.currencyCode)} · '
                  'حتى ${MaterialLocalizations.of(context).formatFullDate(goal.targetDate)}',
                  style: theme.textTheme.bodySmall,
                ),
              if (!completed)
                Text(
                  'يجب أن توفر ${formatMinorUnits(monthly, locale, currencyCode: goal.currencyCode)} شهريًا.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              if (nearDeadline && !completed)
                Text(
                  'موعد الهدف قريب، استمر بالادخار اليومي للوصول في الوقت.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'التقدم: $percentage%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                suggestion,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _ContributionButton(goal: goal),
              const SizedBox(height: 8),
              _ContributionsList(goalId: goal.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionButton extends ConsumerWidget {
  const _ContributionButton({required this.goal});

  final SavingsGoalEntity goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: goal.status == SavingsGoalStatus.completed
            ? null
            : () async {
                final settings = await ref.read(settingsRepositoryProvider).get();
                if (!context.mounted) return;
                final currencyCode = settings?.baseCurrencyCode ?? 'SYP';
                String amountInput = '';
                _ContributionSource source = _ContributionSource.fromBalance;
                String? errorText;
                final result = await showDialog<_ContributionDialogResult>(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setState) => AlertDialog(
                      title: const Text('إضافة دفعة'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (v) => amountInput = v,
                              decoration: InputDecoration(
                                labelText: 'قيمة الدفعة ($currencyCode)',
                                errorText: errorText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<_ContributionSource>(
                              value: source,
                              decoration: const InputDecoration(
                                labelText: 'مصدر الدفعة',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: _ContributionSource.fromBalance,
                                  child: Text('من رصيدي الحالي'),
                                ),
                                DropdownMenuItem(
                                  value: _ContributionSource.external,
                                  child: Text('دفعة خارجية (بدون خصم الرصيد)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => source = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () {
                            final parsed = parseUserAmount(amountInput);
                            if (parsed == null || parsed <= 0) {
                              setState(() => errorText = 'أدخل مبلغًا صالحًا');
                              return;
                            }
                            Navigator.pop(
                              ctx,
                              _ContributionDialogResult(
                                amountMinor: minorFromMajor(parsed),
                                source: _mapSource(source),
                              ),
                            );
                          },
                          child: const Text('تأكيد'),
                        ),
                      ],
                    ),
                  ),
                );
                if (result == null) return;

                String? linkedExpenseId;
                if (result.source == SavingContributionSource.fromBalance) {
                  if (!context.mounted) return;
                  final ok = await _ensureEnoughBalanceFor(
                    context,
                    ref,
                    requiredMinor: result.amountMinor,
                  );
                  if (!ok) return;
                  linkedExpenseId = await _createLinkedExpense(
                    ref: ref,
                    currencyCode: currencyCode,
                    amountMinor: result.amountMinor,
                    note: 'تحويل للتوفير: ${goal.title}',
                  );
                }

                await ref.read(savingsGoalRepositoryProvider).addContribution(
                  id: goal.id,
                  amountMinor: result.amountMinor,
                  source: result.source,
                  linkedExpenseId: linkedExpenseId,
                  paidAt: DateTime.now(),
                );
                ref.invalidate(savingGoalContributionsProvider(goal.id));
                ref.invalidate(savingsGoalsProvider);
                invalidateFinanceCaches(ref);
              },
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('إضافة دفعة'),
      ),
    );
  }
}

enum _ContributionSource { fromBalance, external }

class _ContributionDialogResult {
  const _ContributionDialogResult({
    required this.amountMinor,
    required this.source,
  });

  final int amountMinor;
  final SavingContributionSource source;
}

class _ContributionsList extends ConsumerWidget {
  const _ContributionsList({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingGoalContributionsProvider(goalId));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final baseCurrencyCode = ref.watch(appSettingsProvider).valueOrNull?.baseCurrencyCode;
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const Text('لا توجد دفعات مسجلة بعد.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الدفعات', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...items.map((c) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  formatMinorUnits(
                    c.amountMinor,
                    locale,
                    currencyCode: baseCurrencyCode,
                  ),
                ),
                subtitle: Text(
                  '${c.source == SavingContributionSource.fromBalance ? 'من الرصيد' : 'خارجي'} · ${MaterialLocalizations.of(context).formatMediumDate(c.createdAt)}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await _editContribution(context, ref, c);
                    } else if (v == 'delete') {
                      await _deleteContribution(context, ref, c);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _editContribution(
    BuildContext context,
    WidgetRef ref,
    SavingGoalContributionEntity c,
  ) async {
    String amountInput = (c.amountMinor / 100).toStringAsFixed(2);
    _ContributionSource source = c.source == SavingContributionSource.fromBalance
        ? _ContributionSource.fromBalance
        : _ContributionSource.external;
    String? errorText;
    final result = await showDialog<_ContributionDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تعديل دفعة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: amountInput,
                  onChanged: (v) => amountInput = v,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_ContributionSource>(
                  value: source,
                  decoration: const InputDecoration(labelText: 'المصدر'),
                  items: const [
                    DropdownMenuItem(
                      value: _ContributionSource.fromBalance,
                      child: Text('من رصيدي الحالي'),
                    ),
                    DropdownMenuItem(
                      value: _ContributionSource.external,
                      child: Text('دفعة خارجية'),
                    ),
                  ],
                  onChanged: (v) => setState(() => source = v ?? source),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final parsed = parseUserAmount(amountInput);
                if (parsed == null || parsed <= 0) {
                  setState(() => errorText = 'أدخل مبلغًا صالحًا');
                  return;
                }
                Navigator.pop(
                  ctx,
                  _ContributionDialogResult(
                    amountMinor: minorFromMajor(parsed),
                    source: _mapSource(source),
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    String? linkedExpenseId = c.linkedExpenseId;
    if (c.source == SavingContributionSource.fromBalance &&
        result.source == SavingContributionSource.external &&
        c.linkedExpenseId != null) {
      await ref.read(expenseRepositoryProvider).delete(c.linkedExpenseId!);
      linkedExpenseId = null;
    } else if (c.source == SavingContributionSource.external &&
        result.source == SavingContributionSource.fromBalance) {
      if (!context.mounted) return;
      final ok = await _ensureEnoughBalanceFor(
        context,
        ref,
        requiredMinor: result.amountMinor,
      );
      if (!ok) return;
      final settings = await ref.read(settingsRepositoryProvider).get();
      linkedExpenseId = await _createLinkedExpense(
        ref: ref,
        currencyCode: settings?.baseCurrencyCode ?? 'SYP',
        amountMinor: result.amountMinor,
        note: 'تحويل للتوفير (تعديل)',
      );
    } else if (result.source == SavingContributionSource.fromBalance &&
        c.linkedExpenseId != null) {
      final oldExpense = await ref.read(expenseRepositoryProvider).getById(c.linkedExpenseId!);
      if (oldExpense != null) {
        await ref.read(expenseRepositoryProvider).upsert(
          ExpenseEntity(
            id: oldExpense.id,
            amountMinor: result.amountMinor,
            categoryId: oldExpense.categoryId,
            currencyCode: oldExpense.currencyCode,
            note: oldExpense.note,
            date: oldExpense.date,
            createdAt: oldExpense.createdAt,
          ),
        );
      }
    }

    await ref.read(savingsGoalRepositoryProvider).updateContribution(
      contributionId: c.id,
      amountMinor: result.amountMinor,
      source: result.source,
      linkedExpenseId: linkedExpenseId,
      updatedAt: DateTime.now(),
    );
    ref.invalidate(savingGoalContributionsProvider(goalId));
    ref.invalidate(savingsGoalsProvider);
    invalidateFinanceCaches(ref);
  }

  Future<void> _deleteContribution(
    BuildContext context,
    WidgetRef ref,
    SavingGoalContributionEntity c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الدفعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    if (c.source == SavingContributionSource.fromBalance && c.linkedExpenseId != null) {
      await ref.read(expenseRepositoryProvider).delete(c.linkedExpenseId!);
    }
    await ref.read(savingsGoalRepositoryProvider).deleteContribution(c.id);
    ref.invalidate(savingGoalContributionsProvider(goalId));
    ref.invalidate(savingsGoalsProvider);
    invalidateFinanceCaches(ref);
  }
}

SavingContributionSource _mapSource(_ContributionSource s) {
  switch (s) {
    case _ContributionSource.fromBalance:
      return SavingContributionSource.fromBalance;
    case _ContributionSource.external:
      return SavingContributionSource.external;
  }
}

Future<bool> _ensureEnoughBalanceFor(
  BuildContext context,
  WidgetRef ref, {
  required int requiredMinor,
}) async {
  final ym = ref.read(selectedMonthProvider);
  final balance = await ref.read(balanceRepositoryProvider).snapshotForMonth(
    year: ym.year,
    month: ym.month,
  );
  if (requiredMinor > balance.currentBalanceMinor) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ أكبر من الرصيد الحالي.')),
      );
    }
    return false;
  }
  return true;
}

Future<String?> _createLinkedExpense({
  required WidgetRef ref,
  required String currencyCode,
  required int amountMinor,
  required String note,
}) async {
  final categories = await ref.read(categoryRepositoryProvider).getAll();
  if (categories.isEmpty) return null;
  final categoryId = categories.any((c) => c.id == 'cat_seed_other')
      ? 'cat_seed_other'
      : categories.first.id;
  final now = DateTime.now().toUtc();
  final date = DateTime.utc(now.year, now.month, now.day);
  final id = const Uuid().v4();
  await ref.read(expenseRepositoryProvider).upsert(
    ExpenseEntity(
      id: id,
      amountMinor: amountMinor,
      categoryId: categoryId,
      currencyCode: currencyCode,
      note: note,
      date: date,
      createdAt: now,
    ),
  );
  return id;
}
