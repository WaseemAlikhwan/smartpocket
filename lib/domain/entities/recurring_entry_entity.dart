enum RecurringEntryKind { income, expense, debtOwedByMe, debtOwedToMe }

class RecurringEntryEntity {
  const RecurringEntryEntity({
    required this.id,
    required this.entryKind,
    required this.title,
    required this.amountMinor,
    required this.currencyCode,
    required this.dayOfMonth,
    required this.isActive,
    required this.payloadJson,
    required this.lastConfirmedYm,
    required this.createdAt,
  });

  final String id;
  final RecurringEntryKind entryKind;
  final String title;
  final int amountMinor;
  final String currencyCode;
  final int dayOfMonth;
  final bool isActive;
  final String payloadJson;
  final String lastConfirmedYm;
  final DateTime createdAt;
}
