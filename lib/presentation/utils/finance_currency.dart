enum FinanceCurrency { syp, usd, eur }

String currencyCode(FinanceCurrency c) {
  return switch (c) {
    FinanceCurrency.syp => 'SYP',
    FinanceCurrency.usd => 'USD',
    FinanceCurrency.eur => 'EUR',
  };
}

FinanceCurrency currencyFromCode(String code) {
  final x = code.toUpperCase();
  if (x == 'USD') return FinanceCurrency.usd;
  if (x == 'EUR') return FinanceCurrency.eur;
  return FinanceCurrency.syp;
}

String currencyArabicName(String code) {
  final x = code.toUpperCase();
  if (x == 'USD') return 'دولار';
  if (x == 'EUR') return 'يورو';
  return 'ليرة سورية';
}
