import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../presentation/screens/add_edit_debt_screen.dart';
import '../../presentation/screens/add_edit_expense_screen.dart';
import '../../presentation/screens/add_edit_income_screen.dart';
import '../../presentation/screens/categories_screen.dart';
import '../../presentation/screens/category_directory_screen.dart';
import '../../presentation/screens/category_details_screen.dart';
import '../../presentation/screens/debts_screen.dart';
import '../../presentation/screens/debt_details_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/incomes_screen.dart';
import '../../presentation/screens/main_shell_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/recurring_entries_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/savings_goals_screen.dart';
import '../../presentation/screens/add_edit_savings_goal_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/add_edit_recurring_entry_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GlobalKey<NavigatorState> shellNavigatorHome =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> shellNavigatorReports =
    GlobalKey<NavigatorState>(debugLabel: 'reports');
final GlobalKey<NavigatorState> shellNavigatorCategories =
    GlobalKey<NavigatorState>(debugLabel: 'categories');
final GlobalKey<NavigatorState> shellNavigatorSettings =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) async {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        DbConstants.tableSettings,
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      final hasOnboarded = rows.isNotEmpty && ((rows.first['onboarding_completed'] as int?) == 1);
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!hasOnboarded && !isOnboarding) return '/onboarding';
      if (hasOnboarded && isOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorHome,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorCategories,
            routes: [
              GoRoute(
                path: '/categories',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CategoriesScreen()),
              ),
              GoRoute(
                path: '/categories/browse',
                builder: (context, state) => const CategoryDirectoryScreen(),
              ),
              GoRoute(
                path: '/categories/:id',
                builder: (context, state) =>
                    CategoryDetailsScreen(categoryId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/expense/add',
                builder: (context, state) => AddEditExpenseScreen(
                  initialCategoryId: state.uri.queryParameters['categoryId'],
                ),
              ),
              GoRoute(
                path: '/expense/edit/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AddEditExpenseScreen(expenseId: id);
                },
              ),
              GoRoute(
                path: '/incomes',
                builder: (context, state) => const IncomesScreen(),
              ),
              GoRoute(
                path: '/income/add',
                builder: (context, state) => const AddEditIncomeScreen(),
              ),
              GoRoute(
                path: '/income/edit/:id',
                builder: (context, state) =>
                    AddEditIncomeScreen(incomeId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/debts',
                builder: (context, state) => const DebtsScreen(),
              ),
              GoRoute(
                path: '/debt/add',
                builder: (context, state) => const AddEditDebtScreen(),
              ),
              GoRoute(
                path: '/debt/:id',
                builder: (context, state) =>
                    DebtDetailsScreen(debtId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/debt/edit/:id',
                builder: (context, state) =>
                    AddEditDebtScreen(debtId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/recurring',
                builder: (context, state) => const RecurringEntriesScreen(),
              ),
              GoRoute(
                path: '/recurring/add',
                builder: (context, state) => const AddEditRecurringEntryScreen(),
              ),
              GoRoute(
                path: '/recurring/edit/:id',
                builder: (context, state) =>
                    AddEditRecurringEntryScreen(entryId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/savings-goals',
                builder: (context, state) => const SavingsGoalsScreen(),
              ),
              GoRoute(
                path: '/savings-goal/add',
                builder: (context, state) => const AddEditSavingsGoalScreen(),
              ),
              GoRoute(
                path: '/savings-goal/edit/:id',
                builder: (context, state) =>
                    AddEditSavingsGoalScreen(goalId: state.pathParameters['id']!),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorReports,
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ReportsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorSettings,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
