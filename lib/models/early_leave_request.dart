import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an early-leave request. Mirrors the POS
/// `HREarlyLeaveRequest['status']` strings exactly
/// (`src/app/main-layout/hr/hr-early-leave-request.model.ts`): keep in sync.
enum EarlyLeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const EarlyLeaveStatus(this.value);

  final String value;

  static EarlyLeaveStatus fromString(String value) {
    final lower = value.toLowerCase();
    return EarlyLeaveStatus.values.firstWhere(
      (s) => s.name == lower || s.value.toLowerCase() == lower,
      orElse: () => EarlyLeaveStatus.pending,
    );
  }
}

/// An employee's request, made in advance, to leave before the end of their
/// shift on a given day. HR approves it in the POS (or a manager in this app);
/// payroll never deducts early check-out minutes on an approved day.
/// Firestore collection: `stores/{storeId}/hr_early_leave_requests`.
class EarlyLeaveRequest {
  EarlyLeaveRequest({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.leaveTime,
    required this.reason,
    required this.status,
    this.actionedBy,
    this.actionedAt,
    this.actionReason,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;

  /// The day they leave early (start of day, store calendar).
  final DateTime date;

  /// Planned leave time, 'HH:mm'.
  final String leaveTime;
  final String reason;
  final EarlyLeaveStatus status;

  final DateTime requestedAt;
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? actionReason;

  factory EarlyLeaveRequest.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDateTime(dynamic ts) {
      if (ts is DateTime) return ts;
      try {
        return (ts as Timestamp).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return EarlyLeaveRequest(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      date: toDateTime(map['date']),
      leaveTime: map['leaveTime'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      status: EarlyLeaveStatus.fromString(map['status'] as String? ?? ''),
      actionedBy: map['actionedBy'] as String?,
      actionedAt:
          map['actionedAt'] == null ? null : toDateTime(map['actionedAt']),
      actionReason: map['actionReason'] as String? ?? '',
      requestedAt: toDateTime(map['requestedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'leaveTime': leaveTime,
      'reason': reason,
      'status': status.value,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }
}
