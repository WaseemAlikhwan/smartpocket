import 'package:flutter_test/flutter_test.dart';

import 'package:smartpocket/presentation/utils/amount_parser.dart';

void main() {
  test('parseUserAmount trims and parses doubles', () {
    expect(parseUserAmount(''), isNull);
    expect(parseUserAmount('  '), isNull);
    expect(parseUserAmount('12,34'), 12.34);
    expect(parseUserAmount('12.34'), 12.34);
    expect(parseUserAmount('1,234.56'), 1234.56);
    expect(parseUserAmount('1200'), 1200);
  });

  test('minorFromMajor converts to minor currency units', () {
    expect(minorFromMajor(10.52), equals(1052));
    expect(minorFromMajor(0.01), equals(1));
  });
}
