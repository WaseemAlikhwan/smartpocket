import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum FinanceTopTab { incomes, expenses, debts }

class FinanceTopTabs extends StatelessWidget {
  const FinanceTopTabs({required this.activeTab, super.key});

  final FinanceTopTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _TopTabItem(
            label: 'الدخل',
            selected: activeTab == FinanceTopTab.incomes,
            onTap: () => context.go('/incomes'),
          ),
          _TopTabItem(
            label: 'المصروف',
            selected: activeTab == FinanceTopTab.expenses,
            onTap: () => context.go('/categories'),
          ),
          _TopTabItem(
            label: 'الديون',
            selected: activeTab == FinanceTopTab.debts,
            onTap: () => context.go('/debts'),
          ),
        ],
      ),
    );
  }
}

class _TopTabItem extends StatelessWidget {
  const _TopTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
