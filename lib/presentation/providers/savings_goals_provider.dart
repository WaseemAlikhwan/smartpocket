import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/saving_goal_contribution_entity.dart';
import 'repository_providers.dart';

final savingsGoalsProvider =
    FutureProvider.autoDispose<List<SavingsGoalEntity>>((ref) {
  return ref.watch(savingsGoalRepositoryProvider).getAll();
});

final savingsGoalByIdProvider =
    FutureProvider.autoDispose.family<SavingsGoalEntity?, String>((ref, id) {
  return ref.watch(savingsGoalRepositoryProvider).getById(id);
});

final savingGoalContributionsProvider = FutureProvider.autoDispose
    .family<List<SavingGoalContributionEntity>, String>((ref, goalId) {
  return ref.watch(savingsGoalRepositoryProvider).listContributions(goalId);
});
