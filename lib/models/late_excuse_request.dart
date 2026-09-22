import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a late-excuse request. Mirrors the POS
/// `HRLateExcuseRequest['status']` strings exactly
/// (`src/app/main-layout/hr/hr-late-excuse-request.model.ts`): keep in sync.
enum LateExcuseStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const LateExcuseStatus(this.value);

  final String value;

  static LateExcuseStatus fromString(String value) {
    final lower = value.toLowerCase();
    return LateExcuseStatus.values.firstWhere(
      (s) => s.name == lower || s.value.toLowerCase() == lower,
      orElse: () => LateExcuseStatus.pending,
    );
  }
}

/// An employee's request to have a specific late arrival forgiven, so that
/// day's lateness is excluded from the late-arrival deduction. Employees submit
/// one here (`Pending`); HR approves it in the POS, which flags the referenced
/// attendance record `lateExcused`. Firestore collection:
/// `stores/{storeId}/hr_late_excuse_requests`.
class LateExcuseRequest {
  LateExcuseRequest({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.reason,
    required this.status,
    this.attendanceId,
    this.lateMinutes,
    this.actionedBy,
    this.actionedAt,
    this.actionReason,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;

  /// The late day being excused (start of day, store calendar).
  final DateTime date;
  final String reason;
  final LateExcuseStatus status;

  /// The late day's attendance record id, when known at request time.
  final String? attendanceId;

  /// Snapshot of the lateness at request time (informational).
  final int? lateMinutes;

  final DateTime requestedAt;
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? actionReason;

  factory LateExcuseRequest.fromMap(String id, Map<String, dynamic> map) {
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

    return LateExcuseRequest(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      date: toDateTime(map['date']),
      reason: map['reason'] as String? ?? '',
      status: LateExcuseStatus.fromString(map['status'] as String? ?? ''),
      attendanceId: map['attendanceId'] as String?,
      lateMinutes: (map['lateMinutes'] as num?)?.toInt(),
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
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'status': status.value,
      if (attendanceId != null) 'attendanceId': attendanceId,
      if (lateMinutes != null) 'lateMinutes': lateMinutes,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }
}
