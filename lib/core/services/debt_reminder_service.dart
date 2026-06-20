import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/debt_entity.dart';
import '../../presentation/providers/repository_providers.dart';
import 'notification_service.dart';

class DebtReminderService {
  DebtReminderService(this._ref);

  final WidgetRef _ref;

  Future<void> processDueReminders() async {
    final repo = _ref.read(debtRepositoryProvider);
    final now = DateTime.now().toUtc();
    final due = await repo.getDebtsNeedingReminder(now: now);
    for (final debt in due) {
      await NotificationService.instance.showReminder(
        id: debt.id.hashCode,
        title: 'تذكير دين',
        body: _buildBody(debt, now),
      );
      await repo.markReminderSent(debt.id, now);
    }
  }

  String _buildBody(DebtEntity d, DateTime now) {
    final dueDate = DateTime.utc(d.dueDate.year, d.dueDate.month, d.dueDate.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = dueDate.difference(today).inDays;
    final name = d.personName;
    if (days <= 0) {
      return 'موعد سداد دين $name هو اليوم.';
    }
    return 'باقي $days يوم على استحقاق دين $name.';
  }
}

