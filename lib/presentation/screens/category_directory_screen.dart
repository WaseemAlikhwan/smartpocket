import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/value_objects/budget_alert_period.dart';
import '../providers/budget_month_provider.dart';
import '../providers/categories_list_provider.dart';
import '../utils/category_icon.dart';

/// قائمة الفئات مع شارة نوع الميزانية — تُفتح من شاشة المصروف بدل عرض كل الفئات دفعة واحدة.
class CategoryDirectoryScreen extends ConsumerWidget {
  const CategoryDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsForSelectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('الفئات'),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (categories) {
          final budgetById = budgetsAsync.maybeWhen(
            data: (list) => {for (final b in list) b.categoryId: b},
            orElse: () => <String, BudgetEntity>{},
          );

          if (categories.isEmpty) {
            return const Center(child: Text('لا توجد فئات.'));
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'اضغط على فئة لعرض عملياتها وميزانيتها.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ...categories.map((c) => _CategoryDirectoryTile(
                    category: c,
                    budget: budgetById[c.id],
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryDirectoryTile extends StatelessWidget {
  const _CategoryDirectoryTile({
    required this.category,
    required this.budget,
  });

  final CategoryEntity category;
  final BudgetEntity? budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.35),
            radius: 22,
            child: Icon(
              resolveCategoryIcon(category.iconKey),
              color: theme.colorScheme.onSurface,
            ),
          ),
          title: Text(
            category.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: budget != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      label: Text(
                        _budgetPeriodChipLabel(budget!.alertPeriod),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push('/categories/${category.id}'),
        ),
      ),
    );
  }
}

String _budgetPeriodChipLabel(BudgetAlertPeriod p) {
  switch (p) {
    case BudgetAlertPeriod.month:
      return 'ميزانية شهرية';
    case BudgetAlertPeriod.week:
      return 'ميزانية أسبوعية';
    case BudgetAlertPeriod.day:
      return 'ميزانية يومية';
  }
}
