enum DebtType { owedByMe, owedToMe }

enum DebtStatus { pending, paid }

class DebtEntity {
  const DebtEntity({
    required this.id,
    required this.amountMinor,
    required this.paidAmountMinor,
    required this.remainingAmountMinor,
    required this.currencyCode,
    required this.personName,
    this.contactId,
    required this.dueDate,
    required this.type,
    required this.status,
    required this.note,
    required this.createdAt,
    this.lastPaymentAt,
    this.reminderLastSentAt,
  });

  final String id;
  final int amountMinor;
  final int paidAmountMinor;
  final int remainingAmountMinor;
  final String currencyCode;
  final String personName;
  final String? contactId;
  final DateTime dueDate;
  final DebtType type;
  final DebtStatus status;
  final DateTime? lastPaymentAt;
  final DateTime? reminderLastSentAt;
  final String note;
  final DateTime createdAt;
}
