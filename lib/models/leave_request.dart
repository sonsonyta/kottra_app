import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveType {
  sick('Sick Leave'),
  paid('Paid Leave'),
  other('Other'),
  unpaid('Unpaid Leave'),
  annual('Annual Leave');

  const LeaveType(this.value);

  /// The string value to display or store.
  final String value;

  static LeaveType fromString(String value) {
    return LeaveType.values.firstWhere(
      (s) => s.name == value || s.value == value,
      orElse: () => LeaveType.other,
    );
  }
}

enum LeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const LeaveStatus(this.value);

  final String value;

  static LeaveStatus fromString(String value) {
    final lower = value.toLowerCase();
    return LeaveStatus.values.firstWhere(
      (s) => s.name == lower || s.value.toLowerCase() == lower,
      orElse: () => LeaveStatus.pending,
    );
  }
}

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.reason,
    this.actionedBy,
    this.actionedAt,
    this.actionReason,
    this.attachmentUrl,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveType type;
  final LeaveStatus status;
  final String reason;
  final String? attachmentUrl;
  final DateTime requestedAt;
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? actionReason;

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> map) {

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

    return LeaveRequest(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      startDate: toDateTime(map['startDate']),
      endDate: toDateTime(map['endDate']),
      type: LeaveType.fromString(map['type'] as String? ?? ''),
      status: LeaveStatus.fromString(map['status'] as String? ?? ''),
      reason: map['reason'] as String? ?? '',
      actionedBy: map['actionedBy'] as String?,
      actionedAt: toDateTimeNullable(map['actionedAt']),
      actionReason:map['actionReason'] as String? ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      requestedAt: toDateTime(map['requestedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startDate': startDate,
      'endDate': endDate,
      'type': type.value,
      'status': status.value,
      'reason': reason,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Useful for updates where you might only want to update `updatedAt` server timestamp.
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.value
    };
  }
}
