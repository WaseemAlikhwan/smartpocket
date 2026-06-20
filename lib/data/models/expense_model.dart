import '../../core/constants/db_constants.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.amountMinor,
    required super.categoryId,
    required super.currencyCode,
    required super.note,
    required super.date,
    required super.createdAt,
  });

  factory ExpenseModel.fromRow(Map<String, Object?> map) {
    return ExpenseModel(
      id: map['id']! as String,
      amountMinor: map['amount_minor']! as int,
      categoryId: map['category_id']! as String,
      currencyCode: (map['currency_code'] as String?) ?? 'SYP',
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date']! as String),
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'amount_minor': amountMinor,
    'category_id': categoryId,
    'currency_code': currencyCode,
    'note': note,
    'date': date.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableExpenses;
}
