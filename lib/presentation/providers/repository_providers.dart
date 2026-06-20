import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/budget_local_datasource.dart';
import '../../data/datasources/local/category_local_datasource.dart';
import '../../data/datasources/local/debt_local_datasource.dart';
import '../../data/datasources/local/expense_local_datasource.dart';
import '../../data/datasources/local/income_local_datasource.dart';
import '../../data/datasources/local/recurring_local_datasource.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/datasources/local/savings_goal_local_datasource.dart';
import '../../data/repositories/balance_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/savings_goal_repository_impl.dart';
import '../../data/services/report_export_service.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import 'database_provider.dart';

final categoryLocalDsProvider = Provider((ref) {
  return CategoryLocalDataSource(ref.watch(databaseProvider));
});

final expenseLocalDsProvider = Provider((ref) {
  return ExpenseLocalDataSource(ref.watch(databaseProvider));
});

final budgetLocalDsProvider = Provider((ref) {
  return BudgetLocalDataSource(ref.watch(databaseProvider));
});
final settingsLocalDsProvider = Provider((ref) {
  return SettingsLocalDataSource(ref.watch(databaseProvider));
});
final savingsGoalLocalDsProvider = Provider((ref) {
  return SavingsGoalLocalDataSource(ref.watch(databaseProvider));
});
final incomeLocalDsProvider = Provider((ref) {
  return IncomeLocalDataSource(ref.watch(databaseProvider));
});
final debtLocalDsProvider = Provider((ref) {
  return DebtLocalDataSource(ref.watch(databaseProvider));
});
final recurringLocalDsProvider = Provider((ref) {
  return RecurringLocalDataSource(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryLocalDsProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(expenseLocalDsProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(budgetLocalDsProvider));
});
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDsProvider));
});
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepositoryImpl(ref.watch(savingsGoalLocalDsProvider));
});
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepositoryImpl(ref.watch(incomeLocalDsProvider));
});
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(debtLocalDsProvider));
});
final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepositoryImpl(ref.watch(recurringLocalDsProvider));
});
final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepositoryImpl(
    ref.watch(settingsRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
    ref.watch(debtRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    ref.watch(expenseRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
    ref.watch(budgetRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(balanceRepositoryProvider),
  );
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    ref.watch(expenseRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final reportExportServiceProvider = Provider((ref) {
  return ReportExportService(
    ref.watch(expenseLocalDsProvider),
    ref.watch(incomeLocalDsProvider),
    ref.watch(categoryLocalDsProvider),
  );
});
