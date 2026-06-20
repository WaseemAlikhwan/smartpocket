import '../../core/constants/db_constants.dart';
import '../../domain/entities/income_entity.dart';

class IncomeModel extends IncomeEntity {
  const IncomeModel({
    required super.id,
    required super.amountMinor,
    required super.currencyCode,
    required super.date,
    required super.source,
    required super.createdAt,
  });

  factory IncomeModel.fromRow(Map<String, Object?> map) {
    return IncomeModel(
      id: map['id']! as String,
      amountMinor: map['amount_minor']! as int,
      currencyCode: (map['currency_code'] as String?) ?? 'SYP',
      date: DateTime.parse(map['date']! as String),
      source: (map['source'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'amount_minor': amountMinor,
    'currency_code': currencyCode,
    'date': date.toUtc().toIso8601String(),
    'source': source,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static String get table => DbConstants.tableIncomes;
}
