import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/default_categories.dart';
import '../../domain/entities/category_entity.dart';
import 'repository_providers.dart';

final categoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((
  ref,
) async {
  final all = await ref.watch(categoryRepositoryProvider).getAll();
  final rank = <String, int>{
    for (var i = 0; i < defaultCategories.length; i++) defaultCategories[i].id: i,
  };
  final fixed = all.where((c) => rank.containsKey(c.id)).toList();
  fixed.sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
  return fixed;
});
