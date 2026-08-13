import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_employee.dart';

/// Status of a salary advance. Mirrors the POS `HRSalaryAdvance['status']`
/// strings exactly (`lib`/`hr-salary-advance.model.ts`): keep them in sync.
enum AdvanceStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  deducted('Deducted');

  const AdvanceStatus(this.value);

  final String value;

  static AdvanceStatus fromString(String value) {
    final lower = value.toLowerCase();
    return AdvanceStatus.values.firstWhere(
      (s) => s.name == lower || s.value.toLowerCase() == lower,
      orElse: () => AdvanceStatus.pending,
    );
  }
}

/// A salary advance: money paid before payday, deducted in full on the next
/// payroll run. Employees request one here (`source: 'mobile'`, `Pending`); HR
/// approves it (or posts one directly) in the POS. Firestore collection:
/// `stores/{storeId}/hr_salary_advances`.
class SalaryAdvance {
  SalaryAdvance({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    this.source = 'mobile',
    this.actionedBy,
    this.actionedAt,
    this.actionReason,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;
  final double amount;
  final SalaryCurrency currency;
  final String reason;
  final AdvanceStatus status;
  final String source;
  final DateTime requestedAt;
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? actionReason;

  factory SalaryAdvance.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDateTime(dynamic ts) {
      if (ts is DateTime) return ts;
      try {
        return (ts as Timestamp).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? toDateTimeNullable(dynamic ts) {
      if (ts == null) return null;
      return toDateTime(ts);
    }

    return SalaryAdvance(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      currency: SalaryCurrency.fromString(map['currency'] as String? ?? 'USD'),
      reason: map['reason'] as String? ?? '',
      status: AdvanceStatus.fromString(map['status'] as String? ?? ''),
      source: map['source'] as String? ?? 'mobile',
      actionedBy: map['actionedBy'] as String?,
      actionedAt: toDateTimeNullable(map['actionedAt']),
      actionReason: map['actionReason'] as String? ?? '',
      requestedAt: toDateTime(map['requestedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'currency': currency.value,
      'reason': reason,
      'status': status.value,
      'source': source,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }
}
