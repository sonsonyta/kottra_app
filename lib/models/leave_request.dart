import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveType {
  sick('Sick Leave'),
  vacation('Vacation Leave'),
  personal('Personal Leave'),
  unpaid('Unpaid Leave');

  const LeaveType(this.value);

  /// The string value to display or store.
  final String value;

  static LeaveType fromString(String value) {
    return LeaveType.values.firstWhere(
      (s) => s.name == value || s.value == value,
      orElse: () => LeaveType.personal,
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
    return LeaveStatus.values.firstWhere(
      (s) => s.name == value || s.value == value,
      orElse: () => LeaveStatus.pending,
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.reason,
    this.approverId,
    this.attachmentUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveType type;
  final LeaveStatus status;
  final String reason;
  final String? approverId;
  final String? attachmentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDateTime(dynamic ts) {
      if (ts == null) return null;
      if (ts is DateTime) return ts;
      try {
        return (ts as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return LeaveRequest(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      startDate: toDateTime(map['startDate']) ?? DateTime.now(),
      endDate: toDateTime(map['endDate']) ?? DateTime.now(),
      type: LeaveType.fromString(map['type'] as String? ?? ''),
      status: LeaveStatus.fromString(map['status'] as String? ?? ''),
      reason: map['reason'] as String? ?? '',
      approverId: map['approverId'] as String?,
      attachmentUrl: map['attachmentUrl'] as String?,
      createdAt: toDateTime(map['createdAt']),
      updatedAt: toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startDate': startDate,
      'endDate': endDate,
      'type': type.name,
      'status': status.name,
      'reason': reason,
      if (approverId != null) 'approverId': approverId,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Useful for updates where you might only want to update `updatedAt` server timestamp.
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.name,
      if (approverId != null) 'approverId': approverId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
