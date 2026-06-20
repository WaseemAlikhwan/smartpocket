import '../../core/constants/db_constants.dart';
import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.amountMinor,
    required super.paidAmountMinor,
    required super.remainingAmountMinor,
    required super.currencyCode,
    required super.personName,
    super.contactId,
    required super.dueDate,
    required super.type,
    required super.status,
    required super.note,
    required super.createdAt,
    super.lastPaymentAt,
    super.reminderLastSentAt,
  });

  factory DebtModel.fromRow(Map<String, Object?> map) {
    return DebtModel(
      id: map['id']! as String,
      amountMinor: map['amount_minor']! as int,
      paidAmountMinor: (map['paid_amount_minor'] as int?) ?? 0,
      remainingAmountMinor: (map['remaining_amount_minor'] as int?) ?? (map['amount_minor']! as int),
      currencyCode: (map['currency_code'] as String?) ?? 'SYP',
      personName: map['person_name']! as String,
      contactId: map['contact_id'] as String?,
      dueDate: DateTime.parse(map['due_date']! as String),
      type: (map['debt_type'] as String) == 'owed_to_me'
          ? DebtType.owedToMe
          : DebtType.owedByMe,
      status: (map['status'] as String) == 'paid'
          ? DebtStatus.paid
          : DebtStatus.pending,
      lastPaymentAt: (map['last_payment_at'] as String?) == null
          ? null
          : DateTime.parse(map['last_payment_at']! as String),
      reminderLastSentAt: (map['reminder_last_sent_at'] as String?) == null
          ? null
          : DateTime.parse(map['reminder_last_sent_at']! as String),
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'amount_minor': amountMinor,
    'paid_amount_minor': paidAmountMinor,
    'remaining_amount_minor': remainingAmountMinor,
    'person_name': personName,
    'contact_id': contactId,
    'due_date': dueDate.toUtc().toIso8601String(),
    'debt_type': type == DebtType.owedToMe ? 'owed_to_me' : 'owed_by_me',
    'status': status == DebtStatus.paid ? 'paid' : 'pending',
    'last_payment_at': lastPaymentAt?.toUtc().toIso8601String(),
    'reminder_last_sent_at': reminderLastSentAt?.toUtc().toIso8601String(),
    'currency_code': currencyCode,
    'note': note,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableDebts;
}
