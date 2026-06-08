import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveType {
  paidLeave('Paid Leave'),
  unpaidLeave('Unpaid Leave'),
  sickLeave('Sick Leave'),
  annualLeave('Annual Leave'),
  other('Other');

  const LeaveType(this.value);

  final String value;

  static LeaveType? fromString(String? value) {
    if (value == null) return null;
    for (final s in LeaveType.values) {
      if (s.value == value) return s;
    }
    return null;
  }
}

enum AttendanceStatus {
  present('Present'),
  absent('Absent'),
  late('Late'),
  leave('Leave'),
  holiday('Holiday');

  const AttendanceStatus(this.value);

  /// The string value stored in Firestore.
  final String value;

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.leaveType,
    this.lateCheckInNote,
    this.earlyCheckOutNote,
    this.leaveNote,
    this.absentNote,
    this.workingHours,
    this.overtimeHours,
    this.location,
  });

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;

  final Timestamp date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  final AttendanceStatus status;
  final LeaveType? leaveType;
  final String? lateCheckInNote;
  final String? earlyCheckOutNote;
  final String? leaveNote;
  final String? absentNote;
  final double? workingHours;
  final double? overtimeHours;
  final GeoPoint? location;

  Duration? get duration {
    if (checkIn == null || checkOut == null) return null;
    return checkOut!.difference(checkIn!);
  }

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDateTime(dynamic ts) {
      if (ts is DateTime) return ts;
      try {
        return (ts as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return AttendanceRecord(
      id: id,
      storeId: map['storeId'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      date: map['date'] is Timestamp
          ? map['date'] as Timestamp
          : (map['date'] is String
              ? Timestamp.fromDate(DateTime.tryParse(map['date'] as String) ?? DateTime.now())
              : Timestamp.now()),
      checkIn: map['checkIn'] != null ? toDateTime(map['checkIn']) : null,
      checkOut: map['checkOut'] != null ? toDateTime(map['checkOut']) : null,
      status: AttendanceStatus.fromString(map['status'] as String),
      leaveType: LeaveType.fromString(map['leaveType'] as String?),
      lateCheckInNote: map['lateCheckInNote'] as String?,
      earlyCheckOutNote: map['earlyCheckOutNote'] as String?,
      leaveNote: map['leaveNote'] as String?,
      absentNote: map['absentNote'] as String?,
      workingHours: (map['workingHours'] as num?)?.toDouble(),
      overtimeHours: (map['overtimeHours'] as num?)?.toDouble(),
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'status': status.value,
        if (leaveType != null) 'leaveType': leaveType!.value,
        if (lateCheckInNote != null) 'lateCheckInNote': lateCheckInNote,
        if (earlyCheckOutNote != null) 'earlyCheckOutNote': earlyCheckOutNote,
        if (leaveNote != null) 'leaveNote': leaveNote,
        if (absentNote != null) 'absentNote': absentNote,
        if (workingHours != null) 'workingHours': workingHours,
        if (overtimeHours != null) 'overtimeHours': overtimeHours,
        if (location != null) 'location': location,
      };
}