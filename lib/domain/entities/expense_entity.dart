class ExpenseEntity {
  const ExpenseEntity({
    required this.id,
    required this.amountMinor,
    required this.categoryId,
    required this.currencyCode,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final int amountMinor;
  final String categoryId;
  final String currencyCode;
  final String note;
  final DateTime date;
  final DateTime createdAt;
}
