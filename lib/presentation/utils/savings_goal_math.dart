import 'dart:math' as math;

int remainingAmountMinor({
  required int targetAmountMinor,
  required int savedAmountMinor,
}) {
  final remaining = targetAmountMinor - savedAmountMinor;
  return remaining < 0 ? 0 : remaining;
}

double progressRatio({
  required int targetAmountMinor,
  required int savedAmountMinor,
}) {
  if (targetAmountMinor <= 0) return 0;
  return (savedAmountMinor / targetAmountMinor).clamp(0.0, 1.0);
}

int monthsUntil(DateTime targetDate, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
  if (!end.isAfter(start)) return 0;
  final days = end.difference(start).inDays;
  return math.max(1, (days / 30).ceil());
}

/// Equal monthly amount to reach [targetAmountMinor] minus [savedAmountMinor].
int monthlySavingsMinor({
  required int targetAmountMinor,
  required int savedAmountMinor,
  required DateTime targetDate,
  DateTime? from,
}) {
  final remaining = remainingAmountMinor(
    targetAmountMinor: targetAmountMinor,
    savedAmountMinor: savedAmountMinor,
  );
  if (remaining <= 0) return 0;
  final months = monthsUntil(targetDate, from: from);
  if (months <= 0) {
    return remaining;
  }
  return (remaining + months - 1) ~/ months;
}

bool isNearDeadline(DateTime targetDate, {int daysThreshold = 30, DateTime? from}) {
  final now = from ?? DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final days = end.difference(start).inDays;
  return days >= 0 && days <= daysThreshold;
}
