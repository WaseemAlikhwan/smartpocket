import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/recurring_entry_entity.dart';
import '../../presentation/providers/repository_providers.dart';
import '../../presentation/utils/invalidate_finance.dart';
import 'notification_service.dart';

class RecurringEngineService {
  RecurringEngineService(this._ref);

  final WidgetRef _ref;

  static String ym(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  Future<void> processDue(BuildContext context, {DateTime? now}) async {
    final current = now ?? DateTime.now();
    final due = await _ref.read(recurringRepositoryProvider).getActive();
    final currentYm = ym(current);
    final today = current.day;

    for (final r in due) {
      if (r.dayOfMonth > today) continue;
      if (r.lastConfirmedYm == currentYm) continue;

      await NotificationService.instance.showReminder(
        id: r.id.hashCode,
        title: 'تذكير مالي شهري',
        body: 'هل تريد تنفيذ "${r.title}" لهذا الشهر؟',
      );
      if (!context.mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تذكير عملية دورية'),
          content: Text('هل تريد إضافة "${r.title}" الآن؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم')),
          ],
        ),
      );
      if (ok != true) continue;

      final runDate = DateTime.utc(current.year, current.month, r.dayOfMonth);
      final payload = _decodePayload(r.payloadJson);
      switch (r.entryKind) {
        case RecurringEntryKind.income:
          await _ref.read(incomeRepositoryProvider).upsert(
            IncomeEntity(
              id: const Uuid().v4(),
              amountMinor: r.amountMinor,
              currencyCode: r.currencyCode,
              date: runDate,
              source: payload['source']?.toString() ?? r.title,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        case RecurringEntryKind.expense:
          final cats = await _ref.read(categoryRepositoryProvider).getAll();
          if (cats.isEmpty) break;
          final categoryId = payload['category_id']?.toString() ?? cats.first.id;
          await _ref.read(expenseRepositoryProvider).upsert(
            ExpenseEntity(
              id: const Uuid().v4(),
              amountMinor: r.amountMinor,
              categoryId: categoryId,
              currencyCode: r.currencyCode,
              note: payload['note']?.toString() ?? r.title,
              date: runDate,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        case RecurringEntryKind.debtOwedByMe:
        case RecurringEntryKind.debtOwedToMe:
          await _ref.read(debtRepositoryProvider).upsert(
            DebtEntity(
              id: const Uuid().v4(),
              amountMinor: r.amountMinor,
              paidAmountMinor: 0,
              remainingAmountMinor: r.amountMinor,
              currencyCode: r.currencyCode,
              personName: payload['person_name']?.toString() ?? 'غير محدد',
              contactId: payload['contact_id']?.toString(),
              dueDate: runDate,
              type: r.entryKind == RecurringEntryKind.debtOwedByMe
                  ? DebtType.owedByMe
                  : DebtType.owedToMe,
              status: DebtStatus.pending,
              lastPaymentAt: null,
              reminderLastSentAt: null,
              note: payload['note']?.toString() ?? r.title,
              createdAt: DateTime.now().toUtc(),
            ),
          );
      }

      await _ref.read(recurringRepositoryProvider).updateLastConfirmedYm(r.id, currentYm);
    }

    invalidateFinanceCaches(_ref);
  }

  Map<String, dynamic> _decodePayload(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return map;
    } catch (_) {
      return {};
    }
    return {};
  }
}
