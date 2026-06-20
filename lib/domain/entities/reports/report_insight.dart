/// Severity of a generated insight, controls UI color and icon.
enum InsightSeverity { info, positive, warning }

/// Stable codes for insight rules; kept stable so analytics or tests can
/// match individual rules without parsing the localized message.
enum InsightCode {
  topCategoryHeavy,
  monthOverMonthUp,
  monthOverMonthDown,
  positiveSavings,
  negativeSavings,
  weekOverWeekUp,
  weekOverWeekDown,
  topSpendingDay,
}

class ReportInsight {
  const ReportInsight({
    required this.code,
    required this.title,
    required this.message,
    required this.severity,
  });

  final InsightCode code;
  final String title;
  final String message;
  final InsightSeverity severity;
}
