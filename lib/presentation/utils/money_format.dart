import 'package:intl/intl.dart';

String formatMinorUnits(int minor, String localeCode, {String? currencyCode}) {
  final major = minor / 100.0;
  return NumberFormat.currency(
    locale: localeCode,
    name: (currencyCode == null || currencyCode.isEmpty) ? 'SYP' : currencyCode,
  ).format(major);
}
