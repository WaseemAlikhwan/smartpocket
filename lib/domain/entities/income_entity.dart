class IncomeEntity {
  const IncomeEntity({
    required this.id,
    required this.amountMinor,
    required this.currencyCode,
    required this.date,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final int amountMinor;
  final String currencyCode;
  final DateTime date;
  final String source;
  final DateTime createdAt;
}
