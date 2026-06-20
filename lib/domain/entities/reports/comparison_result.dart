enum ComparisonDirection { up, down, flat, undefined }

/// Outcome of comparing two scalar amounts (current vs previous period).
///
/// [deltaPct] is `null` when the previous value is zero, since the
/// percentage change is undefined; UI should fall back to absolute deltas
/// in that case.
class ComparisonResult {
  const ComparisonResult({
    required this.currentMinor,
    required this.previousMinor,
    required this.deltaPct,
    required this.direction,
  });

  factory ComparisonResult.from({
    required int currentMinor,
    required int previousMinor,
  }) {
    if (previousMinor == 0) {
      return ComparisonResult(
        currentMinor: currentMinor,
        previousMinor: previousMinor,
        deltaPct: null,
        direction: currentMinor == 0
            ? ComparisonDirection.flat
            : ComparisonDirection.undefined,
      );
    }
    final delta = ((currentMinor - previousMinor) / previousMinor) * 100.0;
    final ComparisonDirection dir;
    if (delta > 0.5) {
      dir = ComparisonDirection.up;
    } else if (delta < -0.5) {
      dir = ComparisonDirection.down;
    } else {
      dir = ComparisonDirection.flat;
    }
    return ComparisonResult(
      currentMinor: currentMinor,
      previousMinor: previousMinor,
      deltaPct: delta,
      direction: dir,
    );
  }

  final int currentMinor;
  final int previousMinor;
  final double? deltaPct;
  final ComparisonDirection direction;

  int get deltaMinor => currentMinor - previousMinor;
}
