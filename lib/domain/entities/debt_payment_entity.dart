class DebtPaymentEntity {
  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.amountMinor,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String debtId;
  final int amountMinor;
  final DateTime paidAt;
  final DateTime createdAt;
}
