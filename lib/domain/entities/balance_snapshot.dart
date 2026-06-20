class BalanceSnapshot {
  const BalanceSnapshot({
    required this.year,
    required this.month,
    required this.openingBalanceMinor,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.debtCashflowMinor,
    required this.currentBalanceMinor,
    required this.netSavingMinor,
  });

  final int year;
  final int month;
  final int openingBalanceMinor;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int debtCashflowMinor;
  final int currentBalanceMinor;
  final int netSavingMinor;
}
