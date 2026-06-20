import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});
