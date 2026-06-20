import '../../core/constants/db_constants.dart';
import '../../domain/entities/recurring_entry_entity.dart';

class RecurringEntryModel extends RecurringEntryEntity {
  const RecurringEntryModel({
    required super.id,
    required super.entryKind,
    required super.title,
    required super.amountMinor,
    required super.currencyCode,
    required super.dayOfMonth,
    required super.isActive,
    required super.payloadJson,
    required super.lastConfirmedYm,
    required super.createdAt,
  });

  factory RecurringEntryModel.fromRow(Map<String, Object?> map) {
    final rawKind = map['entry_kind'] as String;
    final kind = switch (rawKind) {
      'income' => RecurringEntryKind.income,
      'expense' => RecurringEntryKind.expense,
      'debt_owed_to_me' => RecurringEntryKind.debtOwedToMe,
      _ => RecurringEntryKind.debtOwedByMe,
    };
    return RecurringEntryModel(
      id: map['id']! as String,
      entryKind: kind,
      title: map['title']! as String,
      amountMinor: map['amount_minor']! as int,
      currencyCode: (map['currency_code'] as String?) ?? 'SYP',
      dayOfMonth: map['day_of_month']! as int,
      isActive: (map['is_active']! as int) == 1,
      payloadJson: (map['payload_json'] as String?) ?? '{}',
      lastConfirmedYm: (map['last_confirmed_ym'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'entry_kind': switch (entryKind) {
      RecurringEntryKind.income => 'income',
      RecurringEntryKind.expense => 'expense',
      RecurringEntryKind.debtOwedByMe => 'debt_owed_by_me',
      RecurringEntryKind.debtOwedToMe => 'debt_owed_to_me',
    },
    'title': title,
    'amount_minor': amountMinor,
    'currency_code': currencyCode,
    'day_of_month': dayOfMonth,
    'is_active': isActive ? 1 : 0,
    'payload_json': payloadJson,
    'last_confirmed_ym': lastConfirmedYm,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableRecurringEntries;
}
