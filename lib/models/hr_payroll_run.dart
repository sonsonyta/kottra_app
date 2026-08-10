import 'package:cloud_firestore/cloud_firestore.dart';

/// A payroll run header. Only the fields the mobile app needs (the month is
/// what lets us tie a payslip to a calendar month, since payslips carry only
/// the run id).
class HRPayrollRun {
  const HRPayrollRun({
    required this.id,
    required this.month,
    required this.title,
    required this.status,
  });

  final String id;
  final DateTime month; // 1st of the payroll month
  final String title;
  final String status;

  factory HRPayrollRun.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(dynamic ts) {
      if (ts is DateTime) return ts;
      try {
        return (ts as Timestamp).toDate();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return HRPayrollRun(
      id: id,
      month: toDate(map['month']),
      title: map['title'] as String? ?? '',
      status: map['status'] as String? ?? '',
    );
  }
}
