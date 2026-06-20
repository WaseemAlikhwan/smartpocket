import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef YearMonth = ({int year, int month});

final selectedMonthProvider = StateProvider<YearMonth>((ref) {
  final n = DateTime.now();
  return (year: n.year, month: n.month);
});
