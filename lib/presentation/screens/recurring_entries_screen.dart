import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/recurring_entry_entity.dart';
import '../providers/recurring_provider.dart';

class RecurringEntriesScreen extends ConsumerWidget {
  const RecurringEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('العناصر المتكررة'),
        actions: [
          IconButton(
            onPressed: () => context.push('/recurring/add'),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: recurring.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد عناصر متكررة'));
          }
          return ListView(
            children: list.map((e) {
              final kind = switch (e.entryKind) {
                RecurringEntryKind.income => 'دخل',
                RecurringEntryKind.expense => 'مصروف',
                RecurringEntryKind.debtOwedByMe => 'دين عليك',
                RecurringEntryKind.debtOwedToMe => 'دين لك',
              };
              return ListTile(
                leading: Icon(
                  e.isActive ? Icons.loop : Icons.loop_outlined,
                  color: e.isActive ? Colors.green : null,
                ),
                title: Text('${e.title} · $kind'),
                subtitle: Text('يوم ${e.dayOfMonth} من كل شهر'),
                trailing: Text(e.isActive ? 'مفعل' : 'موقوف'),
                onTap: () => context.push('/recurring/edit/${e.id}'),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
