double? parseUserAmount(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;

  // Thousands often use commas; decimals may use '.' or ','.
  if (!s.contains('.') && s.contains(',')) {
    final idx = s.lastIndexOf(',');
    if (idx != -1) {
      final head = s.substring(0, idx).replaceAll(',', '');
      final tail = s.substring(idx + 1);
      if (tail.contains(',')) return null;
      s = '$head.$tail';
    }
  } else {
    s = s.replaceAll(',', '');
  }

  return double.tryParse(s);
}

int minorFromMajor(double major) => (major * 100).round();
