class PayrollRecord {
  const PayrollRecord({
    required this.month,
    required this.baseSalary,
    required this.deductions,
    required this.netPay,
    required this.status,
    this.paidDate,
  });

  final String month;
  final double baseSalary;
  final double deductions;
  final double netPay;

  /// 'paid' | 'pending'
  final String status;
  final DateTime? paidDate;
}