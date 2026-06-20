import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recurring_entry_entity.dart';
import 'repository_providers.dart';

final recurringEntriesProvider =
    FutureProvider.autoDispose<List<RecurringEntryEntity>>((ref) async {
  return ref.watch(recurringRepositoryProvider).getAll();
});
