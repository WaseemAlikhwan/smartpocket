/// Half-open interval `[startInclusive, endExclusive)` in **local** time.
///
/// Data sources convert these to UTC ISO strings before querying SQLite,
/// while in-memory comparisons (e.g. labels, day keys) stay in local time
/// to match the user's wall-clock perception.
class PeriodRange {
  const PeriodRange({
    required this.startInclusive,
    required this.endExclusive,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;

  Duration get duration => endExclusive.difference(startInclusive);

  /// Number of whole days covered by the range (rounded up to be safe
  /// across DST transitions).
  int get dayCount {
    final hours = duration.inHours;
    return (hours + 23) ~/ 24;
  }

  /// Returns the same range translated by [delta].
  PeriodRange shift(Duration delta) => PeriodRange(
        startInclusive: startInclusive.add(delta),
        endExclusive: endExclusive.add(delta),
      );
}
