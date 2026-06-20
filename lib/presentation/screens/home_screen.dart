import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';
import '../providers/budget_overrun_provider.dart';
import '../providers/categories_list_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/savings_goals_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/category_icon.dart';
import '../utils/money_format.dart';
import '../utils/savings_goal_math.dart';
import '../widgets/month_nav_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardSnapshotProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final catsAsync = ref.watch(categoriesProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final baseCurrencyCode = settings?.baseCurrencyCode;
    final savingsGoals = ref.watch(savingsGoalsProvider).valueOrNull ?? const <SavingsGoalEntity>[];
    final budgetOverrun = ref.watch(budgetOverrunBannerProvider).valueOrNull;
    final showBudgetWarning = budgetOverrun != null;

    Future<void> onRefresh() async {
      ref.invalidate(dashboardSnapshotProvider);
      ref.invalidate(budgetOverrunBannerProvider);
      ref.invalidate(savingsGoalsProvider);
      await ref.read(dashboardSnapshotProvider.future);
    }

    Map<String, String> iconLookup() => catsAsync.maybeWhen(
      data: (list) => {for (final c in list) c.id: c.iconKey},
      orElse: () => {},
    );

    Map<String, String> nameLookup() => catsAsync.maybeWhen(
      data: (list) => {for (final c in list) c.id: c.name},
      orElse: () => {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروف'),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const MonthNavBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'لوحة المصاريف الشخصية',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            dash.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('$e'),
                  ),
              data: (d) {
                final names = nameLookup();
                final iconsMap = iconLookup();
                final overrunCategoryName =
                    budgetOverrun == null
                        ? ''
                        : (names[budgetOverrun.categoryId] ?? 'هذه الفئة');

                IconData topIcon = Icons.star;
                String topCatLabel = '';
                final tid = d.topCategoryId;
                if (tid != null) {
                  topCatLabel = names[tid] ?? '';
                  topIcon = resolveCategoryIcon(iconsMap[tid] ?? 'category');
                }

                final topSubtitle =
                    tid == null || d.topCategorySpentMinor == 0
                        ? 'لا يوجد صرف هذا الشهر'
                        : '$topCatLabel · ${formatMinorUnits(d.topCategorySpentMinor, locale, currencyCode: baseCurrencyCode)}';
                final overrunPeriodLabel =
                    budgetOverrun == null
                        ? ''
                        : _periodLabel(budgetOverrun.period);
                final bannerText =
                    budgetOverrun == null
                        ? ''
                        : 'تجاوزت المصاريف حدّ الميزانية لفئة $overrunCategoryName خلال $overrunPeriodLabel.';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBudgetWarning)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: MaterialBanner(
                          content: Text(bannerText),
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () =>
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentMaterialBanner(),
                              child: const Text('إخفاء'),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DashCard(
                              title: 'الرصيد الحالي',
                              value: formatMinorUnits(
                                d.currentBalanceMinor,
                                locale,
                                currencyCode: baseCurrencyCode,
                              ),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashCard(
                              title: 'الدخل الشهري',
                              value: formatMinorUnits(
                                d.totalIncomeMinor,
                                locale,
                                currencyCode: baseCurrencyCode,
                              ),
                              icon: Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DashCard(
                              title: 'مجموع المصاريف',
                              value: formatMinorUnits(
                                d.totalSpentMinor,
                                locale,
                                currencyCode: baseCurrencyCode,
                              ),
                              icon: Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashCard(
                              title: 'صافي التوفير',
                              value: formatMinorUnits(
                                d.netSavingMinor,
                                locale,
                                currencyCode: baseCurrencyCode,
                              ),
                              icon: Icons.savings_outlined,
                              highlight: showBudgetWarning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DashCard(
                        title: 'أكثر فئة صرفاً',
                        subtitle: topSubtitle,
                        icon: topIcon,
                        onTap:
                            tid != null && d.topCategorySpentMinor > 0
                                ? () => context.go('/reports')
                                : null,
                      ),
                    ),
                    if (d.insights.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تحليلات ذكية',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                ...d.insights.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('• $m'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SavingGoalsPreviewCard(
                        goals: savingsGoals,
                        locale: locale,
                        currencyCode: baseCurrencyCode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'آخر العمليات',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (d.recentExpenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'لم تُضف مصاريف في هذا الشهر.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...d.recentExpenses.map((e) {
                        final ik = iconsMap[e.categoryId];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                resolveCategoryIcon(ik ?? 'category'),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              e.categoryName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${MaterialLocalizations.of(context).formatFullDate(e.date)} '
                              '${e.note.isNotEmpty ? ' · ${e.note}' : ''}',
                            ),
                            trailing: Text(
                              formatMinorUnits(
                                e.amountMinor,
                                locale,
                                currencyCode: baseCurrencyCode,
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap:
                                () => context.push(
                                  '/expense/edit/${e.expenseId}',
                                ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _periodLabel(BudgetAlertPeriod period) {
  switch (period) {
    case BudgetAlertPeriod.month:
      return 'الشهر';
    case BudgetAlertPeriod.week:
      return 'الأسبوع';
    case BudgetAlertPeriod.day:
      return 'اليوم';
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    required this.icon,
    this.value,
    this.subtitle,
    this.highlight = false,
    this.onTap,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color:
                        highlight
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: highlight ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, maxLines: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingGoalsPreviewCard extends StatelessWidget {
  const _SavingGoalsPreviewCard({
    required this.goals,
    required this.locale,
    required this.currencyCode,
  });

  final List<SavingsGoalEntity> goals;
  final String locale;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (goals.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('أهداف التوفير'),
          subtitle: const Text('لا توجد أهداف بعد. اضغط لإضافة أول هدف.'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push('/savings-goals'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('أهداف التوفير'),
              subtitle: Text('${goals.length} هدف'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/savings-goals'),
            ),
            const SizedBox(height: 6),
            ...goals.take(2).map((g) {
              final ratio = progressRatio(
                targetAmountMinor: g.targetAmountMinor,
                savedAmountMinor: g.savedAmountMinor,
              );
              final remaining = remainingAmountMinor(
                targetAmountMinor: g.targetAmountMinor,
                savedAmountMinor: g.savedAmountMinor,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'المتبقي: ${formatMinorUnits(remaining, locale, currencyCode: g.currencyCode.isEmpty ? currencyCode : g.currencyCode)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: ratio, minHeight: 6),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
