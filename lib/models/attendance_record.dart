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
    this.note,
    this.workingHours,
    this.overtimeHours,
  });

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;

  /// Midnight timestamp — used for querying by day.
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  final AttendanceStatus status;
  final String? note;
  final double? workingHours;
  final double? overtimeHours;

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
      date: toDateTime(map['date']),
      checkIn: map['checkIn'] != null ? toDateTime(map['checkIn']) : null,
      checkOut: map['checkOut'] != null ? toDateTime(map['checkOut']) : null,
      status: AttendanceStatus.fromString(map['status'] as String),
      note: map['note'] as String?,
      workingHours: (map['workingHours'] as num?)?.toDouble(),
      overtimeHours: (map['overtimeHours'] as num?)?.toDouble(),
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
        if (note != null) 'note': note,
        if (workingHours != null) 'workingHours': workingHours,
        if (overtimeHours != null) 'overtimeHours': overtimeHours,
      };
}