import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_employee.dart' show SalaryCurrency;

enum PayslipStatus {
  pending('Pending'),
  paid('Paid');

  const PayslipStatus(this.value);
  final String value;

  static PayslipStatus fromString(String value) => PayslipStatus.values
      .firstWhere((s) => s.value == value, orElse: () => PayslipStatus.pending);
}

class HRPayslip {
  const HRPayslip({
    required this.id,
    required this.payrollRunId,
    required this.employeeId,
    required this.employeeName,
    required this.position,
    required this.basicSalary,
    required this.overtimePay,
    required this.bonuses,
    required this.allowances,
    required this.tax,
    required this.leaveDeduction,
    required this.otherDeductions,
    required this.netSalary,
    required this.currency,
    required this.status,
    this.paidDate,
  });

  final String id;
  final String payrollRunId;
  final String employeeId;
  final String employeeName;
  final String position;

  // Earnings
  final double basicSalary;
  final double overtimePay;
  final double bonuses;
  final double allowances;

  // Deductions
  final double tax;
  final double leaveDeduction;
  final double otherDeductions;

  // Net
  final double netSalary;
  final SalaryCurrency currency;

  final PayslipStatus status;
  final DateTime? paidDate;

  double get grossEarnings =>
      basicSalary + overtimePay + bonuses + allowances;

  double get totalDeductions => tax + leaveDeduction + otherDeductions;

  factory HRPayslip.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDateTimeNullable(dynamic ts) {
      if (ts == null) return null;
      if (ts is DateTime) return ts;
      try {
        return (ts as Timestamp).toDate();
      } catch (_) {
        return null;
      }
    }

    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return HRPayslip(
      id: id,
      payrollRunId: map['payrollRunId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      position: map['position'] as String? ?? '',
      basicSalary: toDouble(map['basicSalary']),
      overtimePay: toDouble(map['overtimePay']),
      bonuses: toDouble(map['bonuses']),
      allowances: toDouble(map['allowances']),
      tax: toDouble(map['tax']),
      leaveDeduction: toDouble(map['leaveDeduction']),
      otherDeductions: toDouble(map['otherDeductions']),
      netSalary: toDouble(map['netSalary']),
      currency: SalaryCurrency.fromString(map['currency'] as String? ?? 'USD'),
      status: PayslipStatus.fromString(map['status'] as String? ?? 'Pending'),
      paidDate: toDateTimeNullable(map['paidDate']),
    );
  }

  Map<String, dynamic> toMap() => {
        'payrollRunId': payrollRunId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'position': position,
        'basicSalary': basicSalary,
        'overtimePay': overtimePay,
        'bonuses': bonuses,
        'allowances': allowances,
        'tax': tax,
        'leaveDeduction': leaveDeduction,
        'otherDeductions': otherDeductions,
        'netSalary': netSalary,
        'currency': currency.value,
        'status': status.value,
        if (paidDate != null) 'paidDate': Timestamp.fromDate(paidDate!),
      };
}
