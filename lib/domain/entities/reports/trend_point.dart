/// Generic time-series point used for daily/monthly bar and line charts.
///
/// [bucketKey] is the canonical SQL bucket label produced via
/// `substr(datetime(date, 'localtime'), 1, N)`:
/// - `yyyy-MM-dd` for daily buckets
/// - `yyyy-MM` for monthly buckets
class TrendPoint {
  const TrendPoint({
    required this.bucketKey,
    required this.label,
    required this.valueMinor,
  });

  final String bucketKey;
  final String label;
  final int valueMinor;
}
